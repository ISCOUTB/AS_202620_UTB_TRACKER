"""
Capa de servicio para préstamos de salón.

Gestiona solicitudes de préstamo de salones validando conflictos
con horarios académicos y otros préstamos existentes.
"""
from datetime import datetime, time as dtime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.schemas.prestamos_salon import PrestamoSalonCreate
from app.services import auditoria, correo, estado_salon

# Las fechas de préstamo se guardan en UTC "naive"; el campus está en UTC-5.
_DESFASE_COLOMBIA = timedelta(hours=-5)
_DIAS = ("lun", "mar", "mié", "jue", "vie", "sáb", "dom")

MSG_PRESTAMO_NO_ENCONTRADO = "Solicitud de salón no encontrada"


def _validar_salon(db: Session, salon_id: int) -> Salon:
    salon = db.query(Salon).filter(Salon.id == salon_id, Salon.activo.is_(True)).first()
    if not salon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Salón no encontrado")
    _exigir_habilitado(salon)
    return salon


def _exigir_habilitado(salon: Salon) -> None:
    """Un salón deshabilitado no se solicita ni se aprueba (ADR-0022)."""
    if not salon.habilitado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"El salón {salon.nombre} no se puede solicitar. "
                   f"{estado_salon.texto_deshabilitado(salon)}",
        )


def _detectar_conflicto_horario(db: Session, salon_id: int, fecha_inicio, fecha_fin):
    """
    Verifica que la franja solicitada no choque con horarios académicos fijos.

    Soporta préstamos que abarcan medianoche: itera cada día cubierto por
    la franja (fecha_inicio.date … fecha_fin.date inclusive) y valida las
    horas que correspondan a ese día.
    """
    dia_actual = fecha_inicio.date()
    dia_fin = fecha_fin.date()

    while dia_actual <= dia_fin:
        dia_semana = dia_actual.isoweekday()  # 1=Lunes … 7=Domingo

        hora_inicio_check = fecha_inicio.time() if dia_actual == fecha_inicio.date() else dtime(0, 0)
        hora_fin_check = fecha_fin.time() if dia_actual == fecha_fin.date() else dtime(23, 59)

        conflicto = db.query(Horario).filter(
            Horario.salon_id == salon_id,
            Horario.dia_semana == dia_semana,
            Horario.activo.is_(True),
            Horario.hora_inicio < hora_fin_check,
            Horario.hora_fin > hora_inicio_check,
        ).first()

        if conflicto:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Conflicto con horario académico: {conflicto.materia or 'clase'} "
                       f"({conflicto.hora_inicio}-{conflicto.hora_fin}, {conflicto.profesor or 'sin profesor'})",
            )

        dia_actual += timedelta(days=1)


def _detectar_conflicto_prestamo(db: Session, salon_id: int, fecha_inicio, fecha_fin, excluir_id: int | None = None):
    """Verifica que no exista otro préstamo de salón aprobado/en_uso que se cruce."""
    query = db.query(PrestamoSalon).filter(
        PrestamoSalon.salon_id == salon_id,
        PrestamoSalon.estado.in_(["pendiente", "aprobado", "en_uso"]),
        PrestamoSalon.fecha_inicio < fecha_fin,
        PrestamoSalon.fecha_fin > fecha_inicio,
    )
    if excluir_id:
        query = query.filter(PrestamoSalon.id != excluir_id)
    conflicto = query.first()
    if conflicto:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ya hay otra solicitud de este salón en esa franja (#{conflicto.id}, {conflicto.estado}).",
        )


def crear_prestamo_salon(db: Session, datos: PrestamoSalonCreate, usuario_id: int) -> PrestamoSalon:
    """
    Crea una solicitud de préstamo de salón.
    Valida que no haya conflictos con horarios académicos ni con otros préstamos.
    """
    _validar_salon(db, datos.salon_id)
    _detectar_conflicto_horario(db, datos.salon_id, datos.fecha_inicio, datos.fecha_fin)
    _detectar_conflicto_prestamo(db, datos.salon_id, datos.fecha_inicio, datos.fecha_fin)

    nuevo = PrestamoSalon(
        salon_id=datos.salon_id,
        usuario_id=usuario_id,
        fecha_inicio=datos.fecha_inicio,
        fecha_fin=datos.fecha_fin,
        motivo=datos.motivo,
    )
    db.add(nuevo)
    db.flush()
    auditoria.registrar(
        db, "salon.solicitud.crear", "prestamo_salon", nuevo.id, actor_id=usuario_id,
        detalle={"salon_id": nuevo.salon_id, "inicio": nuevo.fecha_inicio, "fin": nuevo.fecha_fin},
    )
    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_prestamos_salon(
    db: Session,
    salon_id: int | None = None,
    estado: str | None = None,
    usuario_id: int | None = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[PrestamoSalon], int]:
    """Lista préstamos de salón con filtros opcionales y paginación (sin consultas por fila)."""
    query = _con_relaciones(db.query(PrestamoSalon))
    if salon_id is not None:
        query = query.filter(PrestamoSalon.salon_id == salon_id)
    if estado:
        query = query.filter(PrestamoSalon.estado == estado)
    if usuario_id is not None:
        query = query.filter(PrestamoSalon.usuario_id == usuario_id)
    total = query.order_by(None).count()
    items = query.order_by(PrestamoSalon.created_at.desc()).offset(skip).limit(limit).all()
    return items, total


def obtener_prestamo_salon(
    db: Session, prestamo_id: int, usuario_id: int | None = None
) -> PrestamoSalon:
    """
    Obtiene un préstamo de salón por ID.
    Si se pasa usuario_id, verifica que el préstamo le pertenezca (usuarios normales).
    """
    prestamo = (_con_relaciones(db.query(PrestamoSalon))
                .filter(PrestamoSalon.id == prestamo_id).first())
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)
    if usuario_id is not None and prestamo.usuario_id != usuario_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para consultar este préstamo",
        )
    return prestamo


def actualizar_estado_prestamo_salon(
    db: Session, prestamo_id: int, nuevo_estado: str, actor_id: int | None = None,
    respuesta: Optional[str] = None,
) -> PrestamoSalon:
    """Actualiza el estado de un préstamo de salón (aprobar, rechazar, cancelar, etc.).

    Al aprobar o rechazar guarda quién y cuándo y la respuesta opcional, y avisa al
    estudiante por correo (categoría "salones": respeta sus preferencias). ADR-0018.
    """
    TRANSICIONES_VALIDAS = {
        "pendiente": ["aprobado", "rechazado", "cancelado"],
        "aprobado": ["en_uso", "cancelado"],
        "en_uso": ["finalizado"],
    }

    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)

    estados_permitidos = TRANSICIONES_VALIDAS.get(prestamo.estado, [])
    if nuevo_estado not in estados_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transición no válida: {prestamo.estado} → {nuevo_estado}. "
                   f"Estados permitidos: {estados_permitidos}",
        )

    if nuevo_estado == "aprobado":
        if prestamo.salon is not None:
            _exigir_habilitado(prestamo.salon)
        motivo = _conflictos(db, [prestamo]).get(prestamo.id)
        if motivo:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"No se puede aprobar: la franja choca con {motivo}.",
            )

    anterior = prestamo.estado
    prestamo.estado = nuevo_estado
    respuesta = (respuesta or "").strip() or None
    detalle = {"salon_id": prestamo.salon_id, "de": anterior, "a": nuevo_estado}
    if nuevo_estado in ("aprobado", "rechazado"):
        prestamo.respuesta = respuesta
        prestamo.atendido_por_id = actor_id
        prestamo.atendido_en = datetime.now(timezone.utc).replace(tzinfo=None)
        if respuesta:
            detalle["respuesta"] = respuesta
        _avisar_estudiante(db, prestamo)
    auditoria.registrar(
        db, "salon.solicitud.estado", "prestamo_salon", prestamo.id, actor_id=actor_id,
        detalle=detalle,
    )
    db.commit()
    db.refresh(prestamo)
    return prestamo


def responder_solicitud(
    db: Session, prestamo_id: int, aprobar: bool, actor_id: int, respuesta: Optional[str]
) -> PrestamoSalon:
    """Aprobar o rechazar desde la bandeja del auditor (POST .../aprobar|rechazar)."""
    return actualizar_estado_prestamo_salon(
        db, prestamo_id, "aprobado" if aprobar else "rechazado", actor_id, respuesta
    )


def listar_mias(
    db: Session, usuario_id: int, estado: Optional[str] = None, skip: int = 0, limit: int = 50,
) -> tuple[list[PrestamoSalon], int]:
    """Mis solicitudes (estudiante): siempre filtradas por el dueño."""
    return listar_prestamos_salon(db, None, estado, usuario_id, skip, limit)


def listar_gestion(
    db: Session, estado: Optional[str] = "pendiente", salon_id: Optional[int] = None,
    skip: int = 0, limit: int = 50,
) -> tuple[list[PrestamoSalon], int]:
    """Bandeja del auditor: solicitudes de cualquier estudiante, con el conflicto visible.

    El conflicto de las pendientes se calcula con DOS consultas en total (solicitudes
    aprobadas y clases de los salones de la página), no una por solicitud.
    """
    items, total = listar_prestamos_salon(db, salon_id, estado, None, skip, limit)
    conflictos = _conflictos(db, [p for p in items if p.estado == "pendiente"])
    for p in items:
        p.conflicto = conflictos.get(p.id)
    return items, total


def _con_relaciones(query):
    return query.options(
        joinedload(PrestamoSalon.salon),
        joinedload(PrestamoSalon.usuario),
        joinedload(PrestamoSalon.atendido_por),
    )


def _choca_con_horario(h: Horario, inicio: datetime, fin: datetime) -> bool:
    """¿La clase fija `h` (día de la semana + horas) se cruza con la franja [inicio, fin)?"""
    dia = inicio.date()
    while dia <= fin.date():
        if dia.isoweekday() == h.dia_semana:
            desde = inicio.time() if dia == inicio.date() else dtime(0, 0)
            hasta = fin.time() if dia == fin.date() else dtime(23, 59)
            if h.hora_inicio < hasta and h.hora_fin > desde:
                return True
        dia += timedelta(days=1)
    return False


def _conflictos(db: Session, solicitudes: list[PrestamoSalon]) -> dict[int, str]:
    """{id: texto} de las solicitudes que chocan con otra aprobada/en uso o con una clase."""
    if not solicitudes:
        return {}
    salones = {p.salon_id for p in solicitudes}
    desde = min(p.fecha_inicio for p in solicitudes)
    hasta = max(p.fecha_fin for p in solicitudes)
    aprobados = db.query(PrestamoSalon).filter(
        PrestamoSalon.salon_id.in_(salones),
        PrestamoSalon.estado.in_(["aprobado", "en_uso"]),
        PrestamoSalon.fecha_inicio < hasta,
        PrestamoSalon.fecha_fin > desde,
    ).all()
    clases = db.query(Horario).filter(
        Horario.salon_id.in_(salones), Horario.activo.is_(True)
    ).all()
    resultado: dict[int, str] = {}
    for p in solicitudes:
        otro = next((a for a in aprobados if a.id != p.id and a.salon_id == p.salon_id
                     and a.fecha_inicio < p.fecha_fin and a.fecha_fin > p.fecha_inicio), None)
        if otro:
            resultado[p.id] = f"otra solicitud ya aprobada (#{otro.id})"
            continue
        clase = next((h for h in clases if h.salon_id == p.salon_id
                      and _choca_con_horario(h, p.fecha_inicio, p.fecha_fin)), None)
        if clase:
            resultado[p.id] = (f"la clase {clase.materia or 'programada'} "
                               f"({clase.hora_inicio:%H:%M}-{clase.hora_fin:%H:%M})")
    return resultado


def _franja(p: PrestamoSalon) -> str:
    """'lun 07/01 10:00–11:00' en hora de Colombia."""
    ini, fin = p.fecha_inicio + _DESFASE_COLOMBIA, p.fecha_fin + _DESFASE_COLOMBIA
    return f"{_DIAS[ini.weekday()]} {ini:%d/%m %H:%M}–{fin:%H:%M}"


def _avisar_estudiante(db: Session, p: PrestamoSalon) -> None:
    """Correo al estudiante por el outbox: sale con el mismo commit que el cambio de estado."""
    usuario = p.usuario
    if usuario is None or not usuario.email:
        return
    correo.encolar(db, usuario.email, "solicitud_salon_respuesta", {
        "nombre": usuario.nombre_mostrar or usuario.nombre,
        "salon": p.salon_nombre or f"#{p.salon_id}",
        "franja": _franja(p),
        "estado": p.estado,
        "respuesta": p.respuesta or "",
    }, usuario_id=usuario.id)


def cancelar_prestamo_propio(db: Session, prestamo_id: int, usuario_id: int) -> PrestamoSalon:
    """
    Permite al propietario del préstamo cancelarlo si aún está en estado pendiente.
    Lanza 403 si el préstamo pertenece a otro usuario, 409 si ya no es cancelable.
    """
    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)
    if prestamo.usuario_id != usuario_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo puedes cancelar tus propias solicitudes.",
        )
    if prestamo.estado != "pendiente":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Solo puedes cancelar solicitudes pendientes (esta está {prestamo.estado})."
        )
    prestamo.estado = "cancelado"
    auditoria.registrar(
        db, "salon.solicitud.cancelar", "prestamo_salon", prestamo.id, actor_id=usuario_id,
        detalle={"salon_id": prestamo.salon_id, "de": "pendiente", "a": "cancelado"},
    )
    db.commit()
    db.refresh(prestamo)
    return prestamo


def expirar_prestamos_pendientes(db: Session) -> int:
    """
    Marca como 'cancelado' todos los préstamos pendientes cuya fecha_inicio
    ya pasó (TTL de solicitudes sin respuesta).
    Devuelve el número de registros afectados.
    """
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)  # naïve UTC
    pendientes_vencidos = db.query(PrestamoSalon).filter(
        PrestamoSalon.estado == "pendiente",
        PrestamoSalon.fecha_inicio < ahora,
    ).all()

    for p in pendientes_vencidos:
        p.estado = "cancelado"

    db.commit()
    return len(pendientes_vencidos)
