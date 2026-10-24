"""
Módulo de dominio: préstamos.

Corte vertical S4 / S9: implementa la regla de negocio central del sistema
(documento de idea, sección 6): "un recurso solo puede prestarse si su
estado es disponible".

Refactorización S9 / S11:
- S9 (req. 9.6): Capa de servicio desacoplada.
- S11 (req. 11.3): Soporte para cabecera de idempotencia 'X-Idempotency-Key'.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser
from app.schemas import schemas
from app.services import loans as loans_service

router = APIRouter()


@router.post(
    "",
    response_model=schemas.PrestamoOut,
    status_code=201,
    responses={
        404: {"description": "Recurso o usuario no encontrado"},
        409: {"description": "El recurso no está disponible"},
    },
)
def crear_prestamo(
    prestamo: schemas.PrestamoCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    x_idempotency_key: Annotated[str | None, Header(alias="X-Idempotency-Key")] = None,
):
    return loans_service.crear_prestamo(
        db, prestamo, idempotency_key=x_idempotency_key
    )


@router.get("", response_model=list[schemas.PrestamoOut])
def listar_prestamos(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    estado: Optional[str] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """
    Lista préstamos de recursos.
    Admin/auxiliar ve todos; usuario normal solo ve los suyos.
    """
    usuario_id = None
    if current_user.rol not in ("administrador", "auxiliar"):
        usuario_id = current_user.id
    items, _ = loans_service.listar_prestamos(db, usuario_id, estado, skip, limit)
    return items


@router.patch(
    "/{prestamo_id}/devolver",
    response_model=schemas.PrestamoOut,
    responses={
        404: {"description": "Préstamo no encontrado"},
        409: {"description": "Préstamo ya devuelto"},
    },
)
def devolver_prestamo(
    prestamo_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """
    Registra la devolución de un préstamo.
    Marca fecha_devolucion_real y restaura el recurso a 'disponible'.
    """
    return loans_service.devolver_prestamo(db, prestamo_id)
