"""
Equipamiento de los salones, CALCULADO desde los recursos (ADR-0017).

No se guarda en ninguna tabla: si un equipo se daña, se mueve o se da de baja, el
equipamiento del salón cambia solo. Se calcula con UNA consulta agrupada para todos los
salones pedidos (nunca una consulta por salón).

- total: recursos activos de esa categoría en el salón.
- operativos: de ellos, los que no están dañados ni en mantenimiento.
"""
from typing import Iterable, Optional

from sqlalchemy import and_, case, exists, func
from sqlalchemy.orm import Session

from app.models.recurso_models import Recurso
from app.models.salon_models import Salon
from app.schemas.enums import TipoSalon

ESTADOS_NO_OPERATIVOS = ("dañado", "mantenimiento")
# Orden fijo para mostrar los chips siempre igual.
ORDEN_CATEGORIAS = ("computador", "video_beam", "tv", "audio", "aire_ac", "otro")
MIN_COMPUTADORES_LABORATORIO = 8


def calcular(db: Session, salon_ids: Iterable[int]) -> dict[int, list[dict]]:
    """{salon_id: [{categoria, total, operativos}, ...]} en una sola consulta."""
    ids = list({i for i in salon_ids if i is not None})
    if not ids:
        return {}
    operativo = case((Recurso.estado.in_(ESTADOS_NO_OPERATIVOS), 0), else_=1)
    filas = (
        db.query(
            Recurso.salon_id,
            Recurso.categoria,
            func.count(Recurso.id),
            func.sum(operativo),
        )
        .filter(Recurso.salon_id.in_(ids), Recurso.activo.is_(True))
        .group_by(Recurso.salon_id, Recurso.categoria)
        .all()
    )
    resultado: dict[int, list[dict]] = {i: [] for i in ids}
    for salon_id, categoria, total, operativos in filas:
        resultado[salon_id].append({
            "categoria": categoria,
            "total": int(total),
            "operativos": int(operativos or 0),
        })
    for lista in resultado.values():
        lista.sort(key=lambda e: (
            ORDEN_CATEGORIAS.index(e["categoria"]) if e["categoria"] in ORDEN_CATEGORIAS
            else len(ORDEN_CATEGORIAS),
            e["categoria"],
        ))
    return resultado


def sugerir_tipo(salon: Salon, equipamiento: list[dict]) -> Optional[str]:
    """Regla simple y explicable. Solo SUGIERE: nunca cambia el tipo guardado.

    - 8 o más computadores  -> laboratorio de cómputo
    - capacidad >= 100 con audio o video beam -> auditorio
    - video beam + audio + TV en un salón de menos de 100 -> sala audiovisual
    Devuelve None si la regla no aplica o si ya coincide con el tipo guardado.
    """
    totales = {e["categoria"]: e["total"] for e in equipamiento}
    sugerido = None
    if totales.get("computador", 0) >= MIN_COMPUTADORES_LABORATORIO:
        sugerido = TipoSalon.LABORATORIO_COMPUTO.value
    elif (salon.capacidad or 0) >= 100 and (totales.get("audio") or totales.get("video_beam")):
        sugerido = TipoSalon.AUDITORIO.value
    elif totales.get("video_beam") and totales.get("audio") and totales.get("tv"):
        sugerido = TipoSalon.SALA_AUDIOVISUAL.value
    return None if sugerido == (salon.tipo or "aula") else sugerido


def adjuntar(db: Session, salones: list[Salon]) -> list[Salon]:
    """Pone `equipamiento` y `tipo_sugerido` en cada salón (atributos de respuesta, no columnas)."""
    por_salon = calcular(db, (s.id for s in salones))
    for s in salones:
        s.equipamiento = por_salon.get(s.id, [])
        s.tipo_sugerido = sugerir_tipo(s, s.equipamiento)
    return salones


def filtro_con_equipo(categoria: str):
    """Condición: el salón tiene al menos un equipo OPERATIVO de esa categoría."""
    return exists().where(and_(
        Recurso.salon_id == Salon.id,
        Recurso.categoria == categoria,
        Recurso.activo.is_(True),
        Recurso.estado.notin_(ESTADOS_NO_OPERATIVOS),
    ))
