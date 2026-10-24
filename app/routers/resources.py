"""
Módulo de dominio: recursos.

Corte vertical S4 / S9: crear, listar, actualizar, eliminar y reportar
recursos físicos (equipos electrónicos de salones y laboratorios).
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
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
    current_user: AdminUser,
):
    """Crea un recurso nuevo. Requiere rol admin/auxiliar."""
    return resources_service.crear_recurso(db, recurso)


@router.get("", response_model=list[schemas.RecursoOut])
def listar_recursos(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    salon_id: Optional[int] = None,
    categoria: Optional[str] = None,
    estado: Optional[str] = None,
    busqueda: Optional[str] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """Lista recursos con filtros opcionales y paginación."""
    items, _ = resources_service.listar_recursos(
        db, salon_id, categoria, estado, busqueda, skip, limit
    )
    return items


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
    current_user: CurrentUser,
):
    return resources_service.obtener_recurso(db, recurso_id)


@router.put(
    "/{recurso_id}",
    response_model=schemas.RecursoOut,
    responses={
        404: {"description": "Recurso no encontrado"},
        409: {"description": "Ya existe un recurso con ese serial"},
    },
)
def actualizar_recurso(
    recurso_id: int,
    recurso: schemas.RecursoUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Actualiza un recurso existente. Requiere rol admin/auxiliar."""
    return resources_service.actualizar_recurso(db, recurso_id, recurso)


@router.delete("/{recurso_id}")
def eliminar_recurso(
    recurso_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Soft-delete de un recurso. Requiere rol admin/auxiliar."""
    return resources_service.eliminar_recurso(db, recurso_id)


@router.post(
    "/{recurso_id}/reportar",
    response_model=schemas.ReporteResponse,
    status_code=201,
)
def reportar_recurso(
    recurso_id: int,
    reporte: schemas.ReporteCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """
    Reporta el estado de un recurso (daño, mantenimiento, etc.).
    Crea un registro de reporte y actualiza el estado del recurso.
    """
    return resources_service.reportar_recurso(db, recurso_id, reporte, current_user.id)


@router.get(
    "/{recurso_id}/reportes",
    response_model=list[schemas.ReporteResponse],
)
def listar_reportes_recurso(
    recurso_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Historial de reportes de un recurso."""
    return resources_service.listar_reportes_recurso(db, recurso_id)
