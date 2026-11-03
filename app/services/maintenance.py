from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.recurso_models import MantenimientoRecurso, Recurso
from app.schemas.schemas import MantenimientoRecursoCreate, MantenimientoRecursoUpdate


def crear_mantenimiento(db: Session, datos: MantenimientoRecursoCreate,
                        reporte_id: int | None = None,
                        actualizar_estado: bool = True) -> MantenimientoRecurso:
    recurso = db.query(Recurso).filter(Recurso.id == datos.recurso_id,
                                       Recurso.activo.is_(True)).first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")
    mantenimiento = MantenimientoRecurso(
        **datos.model_dump(), reporte_id=reporte_id, estado="pendiente"
    )
    if actualizar_estado:
        recurso.estado = "mantenimiento"
    db.add(mantenimiento)
    db.flush()
    return mantenimiento


def listar_mantenimientos(db: Session, recurso_id: int | None = None):
    query = db.query(MantenimientoRecurso)
    if recurso_id is not None:
        query = query.filter(MantenimientoRecurso.recurso_id == recurso_id)
    return query.order_by(MantenimientoRecurso.created_at.desc()).all()


def actualizar_mantenimiento(db: Session, mantenimiento_id: int,
                             datos: MantenimientoRecursoUpdate):
    item = db.query(MantenimientoRecurso).filter(
        MantenimientoRecurso.id == mantenimiento_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Mantenimiento no encontrado")
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(item, campo, valor)
    if item.estado == "completado":
        recurso = db.query(Recurso).filter(Recurso.id == item.recurso_id).first()
        if recurso:
            recurso.estado = "disponible"
    db.commit()
    db.refresh(item)
    return item
