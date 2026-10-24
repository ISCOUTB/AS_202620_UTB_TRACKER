"""
Router del módulo de Préstamos de Salón.

Solicitudes de préstamo de salones con validación de conflictos
contra horarios académicos y otros préstamos.
Endpoints protegidos con JWT.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.prestamos_salon import (
    PrestamoSalonCreate,
    PrestamoSalonResponse,
    PrestamoSalonUpdate,
)
from app.services import prestamos_salon as ps_service

router = APIRouter()


@router.post("", response_model=PrestamoSalonResponse, status_code=201)
def crear_prestamo_salon(
    prestamo: PrestamoSalonCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """
    Solicita un préstamo de salón.
    Valida conflictos con horarios académicos y otros préstamos existentes.
    El usuario autenticado queda asociado como solicitante.
    """
    return ps_service.crear_prestamo_salon(db, prestamo, current_user.id)


@router.get("", response_model=list[PrestamoSalonResponse])
def listar_prestamos_salon(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    salon_id: Optional[int] = None,
    estado: Optional[str] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """
    Lista préstamos de salón con filtros.
    Admin/auxiliar ve todos; usuario normal solo ve los suyos.
    """
    usuario_id = None
    if current_user.rol not in ("administrador", "auxiliar"):
        usuario_id = current_user.id
    items, _ = ps_service.listar_prestamos_salon(db, salon_id, estado, usuario_id, skip, limit)
    return items


@router.patch("/{prestamo_id}", response_model=PrestamoSalonResponse)
def actualizar_estado_prestamo_salon(
    prestamo_id: int,
    datos: PrestamoSalonUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """
    Actualiza el estado de un préstamo de salón.
    Solo admin/auxiliar puede aprobar, rechazar o cambiar estados.
    Valida transiciones: pendiente→aprobado/rechazado/cancelado,
    aprobado→en_uso/cancelado, en_uso→finalizado.
    """
    return ps_service.actualizar_estado_prestamo_salon(db, prestamo_id, datos.estado)
