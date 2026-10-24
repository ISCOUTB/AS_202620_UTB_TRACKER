"""
Router del módulo de Salones.

CRUD completo de salones con control de acceso y consulta de disponibilidad.
Endpoints protegidos con JWT; operaciones de escritura requieren rol admin/auxiliar.
"""
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.salones import SalonCreate, SalonResponse, SalonUpdate
from app.services import salones as salones_service

router = APIRouter()


@router.post("", response_model=SalonResponse, status_code=201)
def crear_salon(
    salon: SalonCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Crea un nuevo salón. Requiere rol administrador o auxiliar."""
    return salones_service.crear_salon(db, salon)


@router.get("", response_model=list[SalonResponse])
def listar_salones(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    estado: Optional[str] = None,
    edificio: Optional[str] = None,
    busqueda: Optional[str] = None,
):
    """Lista salones con filtros opcionales y paginación."""
    items, _ = salones_service.listar_salones(db, skip, limit, estado, edificio, busqueda)
    return items


@router.get("/{salon_id}", response_model=SalonResponse)
def obtener_salon(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Obtiene un salón por ID."""
    return salones_service.obtener_salon(db, salon_id)


@router.put("/{salon_id}", response_model=SalonResponse)
def actualizar_salon(
    salon_id: int,
    salon: SalonUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Actualiza un salón existente. Requiere rol admin/auxiliar."""
    return salones_service.actualizar_salon(db, salon_id, salon)


@router.delete("/{salon_id}")
def eliminar_salon(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Soft-delete de un salón. Requiere rol admin/auxiliar."""
    return salones_service.eliminar_salon(db, salon_id)


@router.get("/{salon_id}/disponibilidad")
def obtener_disponibilidad(
    salon_id: int,
    dia_semana: int = Query(..., ge=1, le=7, description="1=Lunes, 7=Domingo"),
    fecha: Optional[date] = None,
    db: Annotated[Session, Depends(get_db)] = None,
    current_user: CurrentUser = None,
):
    """
    Consulta las franjas horarias disponibles de un salón en un día dado.
    Cruza los horarios académicos fijos con los préstamos de salón existentes.
    """
    return salones_service.obtener_disponibilidad(db, salon_id, dia_semana, fecha)
