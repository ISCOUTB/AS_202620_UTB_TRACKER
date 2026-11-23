"""Acceso a datos de mantenimientos de recursos."""
from sqlalchemy.orm import Session

from app.models.recurso_models import MantenimientoRecurso, Recurso


def recurso_activo(db: Session, recurso_id: int) -> Recurso | None:
    return db.query(Recurso).filter(Recurso.id == recurso_id, Recurso.activo.is_(True)).first()


def recurso_por_id(db: Session, recurso_id: int) -> Recurso | None:
    return db.query(Recurso).filter(Recurso.id == recurso_id).first()


def agregar(db: Session, mantenimiento: MantenimientoRecurso) -> MantenimientoRecurso:
    db.add(mantenimiento)
    db.flush()
    return mantenimiento


def listar(db: Session, recurso_id: int | None = None) -> list[MantenimientoRecurso]:
    query = db.query(MantenimientoRecurso)
    if recurso_id is not None:
        query = query.filter(MantenimientoRecurso.recurso_id == recurso_id)
    return query.order_by(MantenimientoRecurso.created_at.desc()).all()


def por_id(db: Session, mantenimiento_id: int) -> MantenimientoRecurso | None:
    return db.query(MantenimientoRecurso).filter(
        MantenimientoRecurso.id == mantenimiento_id).first()
