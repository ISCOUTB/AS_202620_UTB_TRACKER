from typing import Annotated, Optional

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas import schemas
from app.services import maintenance as maintenance_service

router = APIRouter()


@router.post("", response_model=schemas.MantenimientoRecursoOut, status_code=201)
def crear_mantenimiento(datos: schemas.MantenimientoRecursoCreate,
                        db: Annotated[Session, Depends(get_db)],
                        current_user: AdminUser):
    item = maintenance_service.crear_mantenimiento(db, datos)
    db.commit()
    db.refresh(item)
    return item


@router.get("", response_model=list[schemas.MantenimientoRecursoOut])
def listar_mantenimientos(db: Annotated[Session, Depends(get_db)],
                          current_user: CurrentUser,
                          recurso_id: Optional[int] = None):
    return maintenance_service.listar_mantenimientos(db, recurso_id)


@router.patch("/{mantenimiento_id}", response_model=schemas.MantenimientoRecursoOut)
def actualizar_mantenimiento(mantenimiento_id: int,
                              datos: schemas.MantenimientoRecursoUpdate,
                              db: Annotated[Session, Depends(get_db)],
                              current_user: AdminUser):
    return maintenance_service.actualizar_mantenimiento(db, mantenimiento_id, datos)
