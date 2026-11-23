from typing import Annotated, Optional

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import GestionaEquipos
from app.schemas import schemas
from app.services import maintenance as maintenance_service

router = APIRouter()


@router.post("", response_model=schemas.MantenimientoRecursoOut, status_code=201)
def crear_mantenimiento(datos: schemas.MantenimientoRecursoCreate,
                        db: Annotated[Session, Depends(get_db)],
                        current_user: GestionaEquipos):
    return maintenance_service.registrar_mantenimiento(db, datos, actor_id=current_user.id)


@router.get("", response_model=list[schemas.MantenimientoRecursoOut])
def listar_mantenimientos(db: Annotated[Session, Depends(get_db)],
                          current_user: GestionaEquipos,
                          recurso_id: Optional[int] = None):
    return maintenance_service.listar_mantenimientos(db, recurso_id)


@router.patch("/{mantenimiento_id}", response_model=schemas.MantenimientoRecursoOut)
def actualizar_mantenimiento(mantenimiento_id: int,
                              datos: schemas.MantenimientoRecursoUpdate,
                              db: Annotated[Session, Depends(get_db)],
                              current_user: GestionaEquipos):
    return maintenance_service.actualizar_mantenimiento(
        db, mantenimiento_id, datos, actor_id=current_user.id
    )
