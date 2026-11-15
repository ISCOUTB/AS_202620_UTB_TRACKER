"""
Servicio de auditoría.

`registrar` agrega la fila a la MISMA sesión del cambio que se audita y no hace commit: así el
cambio y su registro se confirman (o se revierten) juntos. La bitácora nunca dice algo que no pasó
ni deja de decir algo que sí pasó.
"""
import csv
import io
import json
from datetime import datetime
from typing import Any, Optional

from sqlalchemy.orm import Session

from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario


def _request_id() -> Optional[str]:
    try:
        from app.main import request_id_ctx  # import tardío: app.main importa los routers
        valor = request_id_ctx.get()
        return None if valor == "system" else valor
    except Exception:
        return None


def registrar(
    db: Session,
    accion: str,
    entidad: str,
    entidad_id: Optional[int] = None,
    actor_id: Optional[int] = None,
    detalle: Optional[dict[str, Any]] = None,
    actor_nombre: Optional[str] = None,
) -> RegistroAuditoria:
    """Agrega un registro a la sesión actual (el commit lo hace quien llama)."""
    if actor_nombre is None and actor_id is not None:
        actor = db.query(Usuario.nombre).filter(Usuario.id == actor_id).first()
        actor_nombre = actor[0] if actor else None
    registro = RegistroAuditoria(
        actor_id=actor_id,
        actor_nombre=actor_nombre,
        accion=accion,
        entidad=entidad,
        entidad_id=entidad_id,
        detalle=json.dumps(detalle, ensure_ascii=False, default=str) if detalle else None,
        request_id=_request_id(),
    )
    db.add(registro)
    return registro


def registrar_y_confirmar(db: Session, *args, **kwargs) -> None:
    """Para eventos sin cambio de datos (p. ej. un login fallido): registra y confirma."""
    registrar(db, *args, **kwargs)
    db.commit()


def _filtrar(
    db: Session,
    accion: Optional[str],
    entidad: Optional[str],
    actor_id: Optional[int],
    desde: Optional[datetime],
    hasta: Optional[datetime],
):
    query = db.query(RegistroAuditoria)
    if accion:
        # "salon" encuentra "salon.presencia", "salon.crear"…; "salon.presencia" solo esa.
        query = query.filter(
            (RegistroAuditoria.accion == accion) | RegistroAuditoria.accion.like(f"{accion}.%")
        )
    if entidad:
        query = query.filter(RegistroAuditoria.entidad == entidad)
    if actor_id is not None:
        query = query.filter(RegistroAuditoria.actor_id == actor_id)
    if desde:
        query = query.filter(RegistroAuditoria.ocurrio_en >= desde)
    if hasta:
        query = query.filter(RegistroAuditoria.ocurrio_en <= hasta)
    return query.order_by(RegistroAuditoria.ocurrio_en.desc(), RegistroAuditoria.id.desc())


def listar(
    db: Session,
    accion: Optional[str] = None,
    entidad: Optional[str] = None,
    actor_id: Optional[int] = None,
    desde: Optional[datetime] = None,
    hasta: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 50,
) -> list[RegistroAuditoria]:
    return _filtrar(db, accion, entidad, actor_id, desde, hasta).offset(skip).limit(limit).all()


_COLUMNAS = ["id", "ocurrio_en", "actor_id", "actor_nombre", "accion", "entidad", "entidad_id",
             "detalle", "request_id"]


def exportar_csv(
    db: Session,
    accion: Optional[str] = None,
    entidad: Optional[str] = None,
    actor_id: Optional[int] = None,
    desde: Optional[datetime] = None,
    hasta: Optional[datetime] = None,
    maximo: int = 5000,
) -> str:
    salida = io.StringIO()
    escritor = csv.writer(salida)
    escritor.writerow(_COLUMNAS)
    for r in _filtrar(db, accion, entidad, actor_id, desde, hasta).limit(maximo).all():
        escritor.writerow([getattr(r, c) for c in _COLUMNAS])
    return salida.getvalue()
