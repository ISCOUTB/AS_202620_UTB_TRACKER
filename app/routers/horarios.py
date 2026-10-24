"""
Router del módulo de Horarios.

CRUD de horarios académicos con soporte para carga masiva por semestre.
Endpoints protegidos con JWT; operaciones de escritura requieren rol admin/auxiliar.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.horarios import (
    HorarioBulkCreate,
    HorarioCreate,
    HorarioResponse,
    HorarioUpdate,
)
from app.services import horarios as horarios_service

router = APIRouter()


@router.post("", response_model=HorarioResponse, status_code=201)
def crear_horario(
    horario: HorarioCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Crea un horario académico. Valida conflictos temporales."""
    return horarios_service.crear_horario(db, horario)


@router.post("/bulk", response_model=list[HorarioResponse], status_code=201)
def crear_horarios_bulk(
    datos: HorarioBulkCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Carga masiva de horarios para un semestre completo."""
    return horarios_service.crear_horarios_bulk(db, datos.items)


@router.get("", response_model=list[HorarioResponse])
def listar_horarios(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    salon_id: Optional[int] = None,
    dia_semana: Annotated[Optional[int], Query(ge=1, le=7)] = None,
    semestre: Optional[str] = None,
):
    """Lista horarios con filtros opcionales por salón, día y semestre."""
    return horarios_service.listar_horarios(db, salon_id, dia_semana, semestre)


@router.get("/{horario_id}", response_model=HorarioResponse)
def obtener_horario(
    horario_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Obtiene un horario por ID."""
    return horarios_service.obtener_horario(db, horario_id)


@router.put("/{horario_id}", response_model=HorarioResponse)
def actualizar_horario(
    horario_id: int,
    horario: HorarioUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Actualiza un horario existente. Valida conflictos si cambian las horas."""
    return horarios_service.actualizar_horario(db, horario_id, horario)


@router.delete("/{horario_id}")
def eliminar_horario(
    horario_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Soft-delete de un horario."""
    return horarios_service.eliminar_horario(db, horario_id)
