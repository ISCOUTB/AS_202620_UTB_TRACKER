"""
Estado de un salón: HABILITACIÓN (manual) separada de OCUPACIÓN (calculada). ADR-0022.

- Habilitación: la decide el Administrador o el Auditor. Deshabilitar exige un MOTIVO
  (mantenimiento, daño, evento u otro) y admite una nota y una fecha estimada de reapertura.
  Un salón deshabilitado no se puede solicitar ni aprobar, no aparece disponible y se muestra
  con su motivo. Las solicitudes pendientes o aprobadas futuras quedan SEÑALADAS para el Auditor
  y se avisa a cada estudiante por el outbox (respetando sus preferencias). No se cancelan solas.
- Ocupación: ¿hay una clase (horario, hora del campus UTC-5) o una solicitud aprobada/en uso
  (UTC sin zona) AHORA? No se edita: sale de los datos.

El campo `estado` que reciben los clientes (también las APK viejas) se CALCULA con los dos:
    deshabilitado por mantenimiento      -> "mantenimiento"
    deshabilitado por otro motivo        -> "fuera_servicio"
    habilitado y con clase/solicitud     -> "ocupado"
    habilitado y libre                   -> "disponible"
La columna `estado` guardada solo refleja la habilitación (nunca "ocupado").
Todo se calcula para muchos salones con un número FIJO de consultas (sin N+1).
"""
from datetime import date, datetime, timedelta, timezone
from enum import Enum
from typing import Iterable, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models import salon_models
from app.models.salon_models import Horario, HistorialSalon, PrestamoSalon, Salon
from app.service import auditoria, correo

# Colombia no tiene horario de verano: un desfase fijo evita depender de tzdata.
ZONA_CAMPUS = timezone(timedelta(hours=-5))
ESTADOS_QUE_OCUPAN = ("aprobado", "en_uso")
ESTADOS_AFECTABLES = ("pendiente", "aprobado")
_DIAS = ("lun", "mar", "mié", "jue", "vie", "sáb", "dom")


class MotivoDeshabilitacion(str, Enum):
    MANTENIMIENTO = "mantenimiento"
    DANIO = "danio"
    EVENTO = "evento"
    OTRO = "otro"


ETIQUETAS_MOTIVO = salon_models.ETIQUETAS_MOTIVO


def ahora_campus(momento: Optional[datetime] = None) -> datetime:
    """Hora local del campus (sin zona). `momento` permite simular otra hora en pruebas."""
    if momento is not None:
        return momento.replace(tzinfo=None)
    return datetime.now(ZONA_CAMPUS).replace(tzinfo=None)


def a_utc_naive(local: datetime) -> datetime:
    """Hora local del campus (UTC-5) -> UTC sin zona (como se guardan las solicitudes)."""
    return local + timedelta(hours=5)


def estado_visible(salon: Salon, ocupado: bool) -> str:
    if not salon.habilitado:
        return "mantenimiento" if salon.motivo_deshabilitado == "mantenimiento" else "fuera_servicio"
    return "ocupado" if ocupado else "disponible"


def texto_deshabilitado(salon: Salon) -> Optional[str]:
    """'Deshabilitado: Mantenimiento (…). Reapertura estimada: 20/11/2026.' (vive en el modelo)."""
    return salon.texto_deshabilitado()


# ── Ocupación calculada en lote ───────────────────────────────────────────────

def clases_en_curso(db: Session, ids: list[int], local: datetime) -> dict[int, Horario]:
    """{salon_id: clase en curso} con UNA consulta."""
    if not ids:
        return {}
    filas = db.query(Horario).filter(
        Horario.salon_id.in_(ids),
        Horario.activo.is_(True),
        Horario.dia_semana == local.isoweekday(),
        Horario.hora_inicio <= local.time(),
        Horario.hora_fin > local.time(),
    ).all()
    return {h.salon_id: h for h in sorted(filas, key=lambda h: h.hora_inicio)}


def solicitudes_en_curso(db: Session, ids: list[int], utc: datetime) -> dict[int, PrestamoSalon]:
    """{salon_id: solicitud aprobada/en uso que ocupa el salón ahora} con UNA consulta."""
    if not ids:
        return {}
    filas = (
        db.query(PrestamoSalon)
        .options(joinedload(PrestamoSalon.usuario))
        .filter(
            PrestamoSalon.salon_id.in_(ids),
            PrestamoSalon.estado.in_(ESTADOS_QUE_OCUPAN),
            PrestamoSalon.fecha_inicio <= utc,
            PrestamoSalon.fecha_fin > utc,
        )
        .all()
    )
    resultado: dict[int, PrestamoSalon] = {}
    for p in sorted(filas, key=lambda p: p.estado != "en_uso"):  # 'en_uso' primero
        resultado.setdefault(p.salon_id, p)
    return resultado


def adjuntar(db: Session, salones: Iterable[Salon], momento: Optional[datetime] = None) -> None:
    """Pone `ocupado_ahora`, `estado_visible` y `aviso_deshabilitado` (atributos de respuesta)."""
    salones = list(salones)
    local = ahora_campus(momento)
    ids = [s.id for s in salones]
    ocupados = set(clases_en_curso(db, ids, local)) | set(
        solicitudes_en_curso(db, ids, a_utc_naive(local)))
    for s in salones:
        s.ocupado_ahora = s.habilitado and s.id in ocupados
        s.estado_visible = estado_visible(s, s.id in ocupados)
        s.aviso_deshabilitado = texto_deshabilitado(s)


# ── Habilitación ─────────────────────────────────────────────────────────────

def _franja(p: PrestamoSalon) -> str:
    ini, fin = p.fecha_inicio - timedelta(hours=5), p.fecha_fin - timedelta(hours=5)
    return f"{_DIAS[ini.weekday()]} {ini:%d/%m %H:%M}–{fin:%H:%M}"


def solicitudes_afectadas(db: Session, salon_ids: list[int]) -> list[PrestamoSalon]:
    """Pendientes o aprobadas que todavía no terminan, de los salones dados (UNA consulta)."""
    if not salon_ids:
        return []
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)
    return (
        db.query(PrestamoSalon)
        .options(joinedload(PrestamoSalon.usuario), joinedload(PrestamoSalon.salon))
        .filter(
            PrestamoSalon.salon_id.in_(salon_ids),
            PrestamoSalon.estado.in_(ESTADOS_AFECTABLES),
            PrestamoSalon.fecha_fin > ahora,
        )
        .order_by(PrestamoSalon.fecha_inicio)
        .all()
    )


def validar_datos(habilitado: bool, motivo: Optional[str], nota: Optional[str],
                  reapertura: Optional[date]) -> None:
    if habilitado:
        return
    if not motivo:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                            detail="Elige el motivo para deshabilitar el salón.")
    if motivo == MotivoDeshabilitacion.OTRO.value and not (nota or "").strip():
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                            detail="Con el motivo 'Otro', escribe una nota que lo explique.")
    if reapertura is not None and reapertura < ahora_campus().date():
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                            detail="La fecha de reapertura no puede estar en el pasado.")


def _aplicar(db: Session, salon: Salon, habilitado: bool, motivo: Optional[str],
             nota: Optional[str], reapertura: Optional[date], actor_id: Optional[int]) -> bool:
    """Cambia la habilitación de UN salón en la sesión (sin commit). True si cambió algo."""
    nota = (" ".join((nota or "").split()) or None) if not habilitado else None
    nuevo = (habilitado, motivo if not habilitado else None, nota,
             reapertura if not habilitado else None)
    antes = (salon.habilitado, salon.motivo_deshabilitado, salon.nota_deshabilitado,
             salon.reapertura_estimada)
    if nuevo == antes:
        return False
    salon.habilitado, salon.motivo_deshabilitado, salon.nota_deshabilitado, \
        salon.reapertura_estimada = nuevo
    # La columna guardada sigue la habilitación (valores de siempre, para APK y filtros viejos).
    salon.estado = estado_visible(salon, ocupado=False)
    if habilitado:
        descripcion = "Habilitado"
    else:
        descripcion = texto_deshabilitado(salon).rstrip(".")
    db.add(HistorialSalon(salon_id=salon.id, accion="habilitado" if habilitado else "deshabilitado",
                          descripcion=descripcion[:500], actor_id=actor_id))
    auditoria.registrar(
        db, "salon.habilitacion", "salon", salon.id, actor_id=actor_id,
        detalle={"nombre": salon.nombre, "de": antes[0], "a": habilitado, "motivo": motivo,
                 "nota": nota, "reapertura": reapertura},
    )
    return True


def _avisar(db: Session, afectadas: list[PrestamoSalon]) -> None:
    """Un correo por solicitud afectada, por el outbox (mismo commit; respeta preferencias)."""
    for p in afectadas:
        u, s = p.usuario, p.salon
        if u is None or not u.email:
            continue
        correo.encolar(db, u.email, "salon_deshabilitado", {
            "nombre": u.nombre_mostrar or u.nombre,
            "salon": s.nombre if s else f"#{p.salon_id}",
            "franja": _franja(p),
            "motivo": ETIQUETAS_MOTIVO.get(s.motivo_deshabilitado or "", "Otro") if s else "",
            "reapertura": f"{s.reapertura_estimada:%d/%m/%Y}" if s and s.reapertura_estimada else "",
        }, usuario_id=u.id)


def cambiar_habilitacion(
    db: Session, salon: Salon, habilitado: bool, motivo: Optional[str], nota: Optional[str],
    reapertura: Optional[date], actor_id: Optional[int], commit: bool = True,
) -> list[PrestamoSalon]:
    """Habilita o deshabilita UN salón. Devuelve las solicitudes afectadas (al deshabilitar)."""
    validar_datos(habilitado, motivo, nota, reapertura)
    cambio = _aplicar(db, salon, habilitado, motivo, nota, reapertura, actor_id)
    afectadas = solicitudes_afectadas(db, [salon.id]) if not habilitado else []
    if cambio and afectadas:
        _avisar(db, afectadas)
    if commit:
        db.commit()
        db.refresh(salon)
    return afectadas


def salones_del_lote(db: Session, edificio: str, piso: Optional[int]) -> list[Salon]:
    query = db.query(Salon).filter(Salon.activo.is_(True), Salon.edificio == edificio)
    if piso is not None:
        query = query.filter(Salon.piso == piso)
    return query.order_by(Salon.nombre).all()


def vista_previa_lote(db: Session, edificio: str, piso: Optional[int], habilitado: bool) -> dict:
    salones = salones_del_lote(db, edificio, piso)
    cambian = [s for s in salones if s.habilitado != habilitado]
    afectadas = solicitudes_afectadas(db, [s.id for s in cambian]) if not habilitado else []
    return {
        "salones": [s.nombre for s in cambian],
        "sin_cambio": [s.nombre for s in salones if s.habilitado == habilitado],
        "solicitudes_afectadas": len(afectadas),
    }


def aplicar_lote(db: Session, edificio: str, piso: Optional[int], habilitado: bool,
                 motivo: Optional[str], nota: Optional[str], reapertura: Optional[date],
                 actor_id: Optional[int]) -> dict:
    """Todo o nada, en UNA transacción: o cambian todos los salones del lote o ninguno."""
    validar_datos(habilitado, motivo, nota, reapertura)
    previa = vista_previa_lote(db, edificio, piso, habilitado)
    cambiados = [s for s in salones_del_lote(db, edificio, piso) if s.habilitado != habilitado]
    for s in cambiados:
        _aplicar(db, s, habilitado, motivo, nota, reapertura, actor_id)
    if not habilitado:
        _avisar(db, solicitudes_afectadas(db, [s.id for s in cambiados]))
    db.commit()
    return previa


def historial(db: Session, salon_id: int, limite: int = 50) -> list[HistorialSalon]:
    return (
        db.query(HistorialSalon)
        .options(joinedload(HistorialSalon.actor))
        .filter(HistorialSalon.salon_id == salon_id)
        .order_by(HistorialSalon.creado_en.desc(), HistorialSalon.id.desc())
        .limit(limite)
        .all()
    )


def registrar_historial(db: Session, salon_id: Optional[int], accion: str, descripcion: str,
                        actor_id: Optional[int]) -> None:
    """Para los cambios de equipos (sin commit: va en la transacción de quien llama)."""
    if salon_id is not None:
        db.add(HistorialSalon(salon_id=salon_id, accion=accion, descripcion=descripcion[:500],
                              actor_id=actor_id))


# ── Ocupación por edificio y piso (cuántos libres ahora) ─────────────────────

def resumen_por_piso(db: Session, momento: Optional[datetime] = None) -> list[dict]:
    salones = db.query(Salon).filter(Salon.activo.is_(True)).all()
    adjuntar(db, salones, momento)
    grupos: dict[tuple, dict] = {}
    for s in salones:
        clave = (s.edificio or "Sin edificio", s.piso)
        g = grupos.setdefault(clave, {"edificio": clave[0], "piso": clave[1], "total": 0,
                                      "libres": 0, "ocupados": 0, "deshabilitados": 0})
        g["total"] += 1
        if not s.habilitado:
            g["deshabilitados"] += 1
        elif s.ocupado_ahora:
            g["ocupados"] += 1
        else:
            g["libres"] += 1
    return [grupos[k] for k in sorted(grupos, key=lambda k: (k[0], k[1] if k[1] is not None else -1))]
