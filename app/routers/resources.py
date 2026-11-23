"""
Módulo de dominio: recursos.

Corte vertical S4 / S9: crear, listar, actualizar, eliminar y reportar
recursos físicos (equipos electrónicos de salones y laboratorios).
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CreaReportes, GestionaEquipos, VeEquipos
from app.schemas import schemas
from app.schemas.equipos import (
    AplicarPlantilla,
    EstadoEquipoResultado,
    EstadoEquipoUpdate,
    Plantilla,
    PlantillaPorSalon,
)
from app.services import equipos as equipos_service
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
    current_user: GestionaEquipos,
):
    """Crea un recurso nuevo. Requiere rol admin/auxiliar."""
    return resources_service.crear_recurso(db, recurso, actor_id=current_user.id)


@router.get("", response_model=list[schemas.RecursoOut])
def listar_recursos(
    db: Annotated[Session, Depends(get_db)],
    current_user: VeEquipos,
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


@router.get("/plantillas", response_model=list[Plantilla])
def listar_plantillas(current_user: GestionaEquipos):
    """Plantillas de equipamiento (aula estándar, laboratorio) (ADR-0022)."""
    return equipos_service.listar_plantillas()


@router.post("/plantillas/vista-previa", response_model=list[PlantillaPorSalon])
def vista_previa_plantilla(
    datos: AplicarPlantilla,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    """Qué se agregaría a cada salón elegido (solo lo que falta). No escribe nada."""
    return equipos_service.vista_previa_plantilla(
        db, datos.plantilla, datos.salon_ids, datos.computadores)


@router.post("/plantillas/aplicar", response_model=list[PlantillaPorSalon])
def aplicar_plantilla(
    datos: AplicarPlantilla,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    """Agrega a los salones elegidos solo los equipos que faltan. Auditado."""
    return equipos_service.aplicar_plantilla(
        db, datos.plantilla, datos.salon_ids, datos.computadores, actor_id=current_user.id)


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
    current_user: VeEquipos,
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
    current_user: GestionaEquipos,
):
    """Actualiza un recurso existente. Requiere rol admin/auxiliar."""
    return resources_service.actualizar_recurso(db, recurso_id, recurso, actor_id=current_user.id)


@router.patch("/{recurso_id}/estado", response_model=EstadoEquipoResultado)
def cambiar_estado_equipo(
    recurso_id: int,
    datos: EstadoEquipoUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    """Operativo / dañado / en mantenimiento (los equipos no se prestan). Si queda dañado,
    sugiere abrir o vincular un reporte de tipo equipo: no lo abre solo."""
    return equipos_service.cambiar_estado(
        db, recurso_id, datos.estado, datos.nota, datos.reporte_salon_id,
        actor_id=current_user.id)


@router.delete("/{recurso_id}")
def eliminar_recurso(
    recurso_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    """Retira el equipo del salón (se desactiva, no se borra). Auditor y Administrador."""
    return resources_service.eliminar_recurso(db, recurso_id, actor_id=current_user.id)


@router.post(
    "/{recurso_id}/reportar",
    response_model=schemas.ReporteResponse,
    status_code=201,
)
def reportar_recurso(
    recurso_id: int,
    reporte: schemas.ReporteCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CreaReportes,
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
    current_user: VeEquipos,
):
    """Historial de reportes de un recurso."""
    return resources_service.listar_reportes_recurso(db, recurso_id)
