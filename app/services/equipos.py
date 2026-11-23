"""
Equipos FIJOS de cada salón (ADR-0010, ADR-0022): NO se prestan.

- Estado de un equipo: operativo (valor guardado "disponible"), dañado o en mantenimiento.
  El estado "prestado" es un resto del préstamo de equipos: aquí se rechaza.
- Un equipo dañado baja "operativos" pero no "total" (el equipamiento se calcula, ADR-0017).
- Al marcarlo dañado NO se abre nada solo: la respuesta SUGIERE abrir un reporte o vincular uno
  de tipo "equipo" que ya esté abierto en el salón; lo decide quien está en la pantalla.
- Plantillas de equipamiento: se aplican SOLO a los salones elegidos y con vista previa; crean
  únicamente lo que falta (nunca duplican ni quitan).
"""
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.recurso_models import Recurso
from app.models.salon_models import ReporteSalon, Salon
from app.services import auditoria, estado_salon

ETIQUETAS_ESTADO = {"disponible": "Operativo", "dañado": "Dañado", "mantenimiento": "En mantenimiento"}
ETIQUETAS_CATEGORIA = {
    "video_beam": "video beam", "computador": "computador", "aire_ac": "aire acondicionado",
    "tv": "televisor", "audio": "sonido", "otro": "otro equipo",
}

# Plantillas (ADR-0022). `computador` del laboratorio = N elegido al aplicar.
PLANTILLAS = {
    "aula_estandar": {
        "nombre": "Aula estándar",
        "descripcion": "1 video beam, 1 aire acondicionado y 1 computador del docente",
        "equipos": {"video_beam": 1, "aire_ac": 1, "computador": 1},
    },
    "laboratorio": {
        "nombre": "Laboratorio de cómputo",
        "descripcion": "N computadores (por defecto 20)",
        "equipos": {"computador": 20},
    },
}
MAX_SALONES_PLANTILLA = 100


def _obtener(db: Session, recurso_id: int) -> Recurso:
    recurso = (db.query(Recurso).options(joinedload(Recurso.salon))
               .filter(Recurso.id == recurso_id, Recurso.activo.is_(True)).first())
    if recurso is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Equipo no encontrado")
    return recurso


def _reportes_equipo_abiertos(db: Session, salon_id: Optional[int]) -> list[ReporteSalon]:
    if salon_id is None:
        return []
    return (db.query(ReporteSalon)
            .filter(ReporteSalon.salon_id == salon_id, ReporteSalon.tipo == "equipo",
                    ReporteSalon.estado == "abierto")
            .order_by(ReporteSalon.created_at.desc()).all())


def _vincular_reporte(
    db: Session, reporte_salon_id: Optional[int], recurso: Recurso,
) -> Optional[ReporteSalon]:
    if reporte_salon_id is None:
        return None
    reporte = db.query(ReporteSalon).filter(ReporteSalon.id == reporte_salon_id).first()
    if reporte is None or reporte.salon_id != recurso.salon_id or reporte.tipo != "equipo":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Ese reporte no es de tipo equipo de este salón.",
        )
    reporte.recurso_id = recurso.id
    return reporte


def _registrar_cambio_estado_equipo(
    db: Session, recurso: Recurso, anterior: str, estado: str,
    nota: Optional[str], reporte: Optional[ReporteSalon], actor_id: Optional[int],
) -> None:
    recurso.estado = estado
    nombre = ETIQUETAS_CATEGORIA.get(recurso.categoria, recurso.categoria)
    texto = (f"Equipo {nombre} {recurso.serial}: "
             f"{ETIQUETAS_ESTADO.get(anterior, anterior)} → {ETIQUETAS_ESTADO[estado]}")
    if nota:
        texto += f" ({nota})"
    if reporte is not None:
        texto += f" · reporte #{reporte.id}"
    estado_salon.registrar_historial(db, recurso.salon_id, "equipo.estado", texto, actor_id)
    auditoria.registrar(
        db, "recurso.estado", "recurso", recurso.id, actor_id=actor_id,
        detalle={"serial": recurso.serial, "salon_id": recurso.salon_id, "de": anterior,
                 "a": estado, "nota": nota,
                 "reporte_salon_id": reporte.id if reporte else None},
    )


def cambiar_estado(
    db: Session, recurso_id: int, estado: str, nota: Optional[str],
    reporte_salon_id: Optional[int], actor_id: Optional[int],
) -> dict:
    if estado not in ETIQUETAS_ESTADO:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Estado no válido: usa operativo, dañado o en mantenimiento "
                   "(los equipos no se prestan).",
        )
    recurso = _obtener(db, recurso_id)
    reporte = _vincular_reporte(db, reporte_salon_id, recurso)
    anterior = recurso.estado
    nota = " ".join((nota or "").split()) or None
    if anterior != estado or reporte is not None:
        _registrar_cambio_estado_equipo(db, recurso, anterior, estado, nota, reporte, actor_id)
    db.commit()
    db.refresh(recurso)
    abiertos = _reportes_equipo_abiertos(db, recurso.salon_id)
    return {
        "recurso": recurso,
        # Sugerencia (sin automatismos): dañado y sin reporte vinculado a este equipo.
        "sugerir_reporte": estado == "dañado" and recurso.salon_id is not None
        and not any(r.recurso_id == recurso.id for r in abiertos),
        "reportes_equipo_abiertos": abiertos,
    }


# ── Plantillas ────────────────────────────────────────────────────────────────

def listar_plantillas() -> list[dict]:
    return [{"id": k, "nombre": v["nombre"], "descripcion": v["descripcion"],
             "equipos": v["equipos"]} for k, v in PLANTILLAS.items()]


def _requeridos(plantilla: str, computadores: Optional[int]) -> dict[str, int]:
    if plantilla not in PLANTILLAS:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                            detail="Plantilla desconocida.")
    equipos = dict(PLANTILLAS[plantilla]["equipos"])
    if plantilla == "laboratorio" and computadores is not None:
        equipos["computador"] = computadores
    return equipos


def vista_previa_plantilla(db: Session, plantilla: str, salon_ids: list[int],
                           computadores: Optional[int] = None) -> list[dict]:
    """Por salón: qué falta para cumplir la plantilla (cuenta los equipos activos que ya hay)."""
    requeridos = _requeridos(plantilla, computadores)
    ids = list(dict.fromkeys(salon_ids))
    if not ids or len(ids) > MAX_SALONES_PLANTILLA:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                            detail=f"Elige entre 1 y {MAX_SALONES_PLANTILLA} salones.")
    salones = {s.id: s for s in db.query(Salon).filter(Salon.id.in_(ids), Salon.activo.is_(True))}
    if len(salones) != len(ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Algún salón elegido no existe o está desactivado.")
    actuales: dict[tuple[int, str], int] = {
        (sid, cat): int(n) for sid, cat, n in
        db.query(Recurso.salon_id, Recurso.categoria, func.count(Recurso.id))
        .filter(Recurso.salon_id.in_(ids), Recurso.activo.is_(True))
        .group_by(Recurso.salon_id, Recurso.categoria).all()
    }
    resultado = []
    for sid in ids:
        faltan = {cat: max(0, n - actuales.get((sid, cat), 0)) for cat, n in requeridos.items()}
        resultado.append({
            "salon_id": sid, "salon_nombre": salones[sid].nombre,
            "agregar": {c: n for c, n in faltan.items() if n > 0},
        })
    return resultado


def _serial_libre(base: str, usados: set[str]) -> str:
    n = 1
    while f"{base}-{n:02d}" in usados:
        n += 1
    serial = f"{base}-{n:02d}"
    usados.add(serial)
    return serial


def aplicar_plantilla(db: Session, plantilla: str, salon_ids: list[int],
                      computadores: Optional[int], actor_id: Optional[int]) -> list[dict]:
    """Crea SOLO lo que la vista previa dice que falta, en UNA transacción."""
    previa = vista_previa_plantilla(db, plantilla, salon_ids, computadores)
    prefijos = [f"{p['salon_nombre']}-" for p in previa if p["agregar"]]
    usados: set[str] = set()
    for prefijo in prefijos:
        usados |= {s for (s,) in db.query(Recurso.serial).filter(Recurso.serial.like(f"{prefijo}%"))}
    creados = 0
    for p in previa:
        for categoria, cantidad in p["agregar"].items():
            for _ in range(cantidad):
                db.add(Recurso(
                    categoria=categoria, salon_id=p["salon_id"], estado="disponible",
                    serial=_serial_libre(f"{p['salon_nombre']}-{categoria.upper()}", usados),
                    descripcion=f"Agregado con la plantilla {PLANTILLAS[plantilla]['nombre']}",
                ))
                creados += 1
        if p["agregar"]:
            resumen = ", ".join(f"{n} {ETIQUETAS_CATEGORIA.get(c, c)}" for c, n in p["agregar"].items())
            estado_salon.registrar_historial(
                db, p["salon_id"], "plantilla",
                f"Plantilla {PLANTILLAS[plantilla]['nombre']}: se agregó {resumen}", actor_id)
    if creados:
        auditoria.registrar(
            db, "recurso.plantilla", "recurso", None, actor_id=actor_id,
            detalle={"plantilla": plantilla, "creados": creados,
                     "salones": [p["salon_nombre"] for p in previa if p["agregar"]]},
        )
    db.commit()
    return previa
