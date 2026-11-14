"""
Router del módulo de Préstamos de Salón.

Solicitudes de préstamo de salones con validación de conflictos
contra horarios académicos y otros préstamos.
Endpoints protegidos con JWT.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Response
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
    response: Response,
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
    Devuelve el total de registros en el header X-Total-Count.
    """
    usuario_id = None
    if current_user.rol not in ("administrador", "auxiliar"):
        usuario_id = current_user.id
    items, total = ps_service.listar_prestamos_salon(db, salon_id, estado, usuario_id, skip, limit)
    response.headers["X-Total-Count"] = str(total)
    return items


@router.get("/{prestamo_id}", response_model=PrestamoSalonResponse)
def obtener_prestamo_salon(
    prestamo_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """
    Obtiene un préstamo de salón por ID.
    Usuario normal solo puede consultar el suyo; admin/auxiliar cualquiera.
    """
    usuario_id = None
    if current_user.rol not in ("administrador", "auxiliar"):
        usuario_id = current_user.id
    return ps_service.obtener_prestamo_salon(db, prestamo_id, usuario_id)


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
    return ps_service.actualizar_estado_prestamo_salon(
        db, prestamo_id, datos.estado, actor_id=current_user.id
    )


@router.delete("/{prestamo_id}", response_model=PrestamoSalonResponse)
def cancelar_prestamo_propio(
    prestamo_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """
    Cancela un préstamo propio que todavía esté en estado 'pendiente'.
    El usuario solo puede cancelar sus propias solicitudes; admin/auxiliar
    deben usar PATCH para cualquier otra transición de estado.
    """
    return ps_service.cancelar_prestamo_propio(db, prestamo_id, current_user.id)


@router.post("/expirar", status_code=200)
def expirar_prestamos_pendientes(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """
    Marca como 'cancelado' todos los préstamos pendientes cuya fecha_inicio
    ya pasó. Debe llamarse periódicamente (cron/scheduler).
    Solo admin/auxiliar.
    """
    total = ps_service.expirar_prestamos_pendientes(db)
    return {"expirados": total}
