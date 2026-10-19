"""
Modulo de dominio: recursos.

Corte vertical S4 / S9: crear y listar recursos (equipos electronicos de
salones/laboratorios). Ver docs/aspectos.md, A-0X, y arc42 seccion 5.2.

Refactorizacion S9 (req. 9.6 - control de erosion arquitectonica):
El router delega la logica de persistencia y validaciones de negocio a
app.services.resources, asegurando capas coherentes en todo el monolito modular.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas import schemas
from app.services import resources as resources_service

router = APIRouter()


@router.post(
    "",
    response_model=schemas.RecursoOut,
    status_code=201,
    responses={
        409: {"description": "Ya existe un recurso con ese serial"},
    },
)
def crear_recurso(
    recurso: schemas.RecursoCreate,
    db: Annotated[Session, Depends(get_db)],
):
    return resources_service.crear_recurso(db, recurso)


@router.get("", response_model=list[schemas.RecursoOut])
def listar_recursos(db: Annotated[Session, Depends(get_db)]):
    return resources_service.listar_recursos(db)


@router.get(
    "/{recurso_id}",
    response_model=schemas.RecursoOut,
    responses={
        404: {"description": "Recurso no encontrado"},
    },
)
def obtener_recurso(
    recurso_id: int,
    db: Annotated[Session, Depends(get_db)],
):
    return resources_service.obtener_recurso(db, recurso_id)
