from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.recurso_models import MantenimientoRecurso
from app.repository import mantenimiento_repository as repo
from app.schemas.schemas import MantenimientoRecursoCreate, MantenimientoRecursoUpdate
from app.service import auditoria


def crear_mantenimiento(db: Session, datos: MantenimientoRecursoCreate,
                        reporte_id: int | None = None,
                        actualizar_estado: bool = True) -> MantenimientoRecurso:
    recurso = repo.recurso_activo(db, datos.recurso_id)
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")
    mantenimiento = MantenimientoRecurso(
        **datos.model_dump(), reporte_id=reporte_id, estado="pendiente"
    )
    if actualizar_estado:
        recurso.estado = "mantenimiento"
    return repo.agregar(db, mantenimiento)


def registrar_mantenimiento(db: Session, datos: MantenimientoRecursoCreate,
                            actor_id: int | None = None) -> MantenimientoRecurso:
    """POST /mantenimientos: crea la orden, la audita y confirma en UNA transacción."""
    item = crear_mantenimiento(db, datos)
    auditoria.registrar(
        db, "mantenimiento.crear", "mantenimiento", item.id, actor_id=actor_id,
        detalle={"recurso_id": item.recurso_id, "tipo": item.tipo},
    )
    db.commit()
    db.refresh(item)
    return item


def listar_mantenimientos(db: Session, recurso_id: int | None = None):
    return repo.listar(db, recurso_id)


def actualizar_mantenimiento(db: Session, mantenimiento_id: int,
                             datos: MantenimientoRecursoUpdate, actor_id: int | None = None):
    item = repo.por_id(db, mantenimiento_id)
    if not item:
        raise HTTPException(status_code=404, detail="Mantenimiento no encontrado")
    cambios = datos.model_dump(exclude_unset=True)
    estado_anterior = item.estado
    for campo, valor in cambios.items():
        setattr(item, campo, valor)
    auditoria.registrar(
        db, "mantenimiento.actualizar", "mantenimiento", item.id, actor_id=actor_id,
        detalle={"recurso_id": item.recurso_id, "estado_de": estado_anterior,
                 "estado_a": item.estado, "campos": list(cambios)},
    )
    if item.estado == "completado":
        recurso = repo.recurso_por_id(db, item.recurso_id)
        if recurso:
            recurso.estado = "disponible"
    db.commit()
    db.refresh(item)
    return item
