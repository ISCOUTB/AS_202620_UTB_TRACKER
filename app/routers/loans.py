"""
Modulo de dominio: prestamos.

Corte vertical S4 / S9: implementa la regla de negocio central del sistema
(documento de idea, seccion 6): "un recurso solo puede prestarse si su
estado es disponible".

Refactorizacion S9 / S11:
- S9 (req. 9.6): Capa de servicio desacoplada.
- S11 (req. 11.3): Soporte para cabecera de idempotencia 'X-Idempotency-Key'.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, Header
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas import schemas
from app.services import loans as loans_service

router = APIRouter()


@router.post(
    "",
    response_model=schemas.PrestamoOut,
    status_code=201,
    responses={
        404: {"description": "Recurso no encontrado"},
        409: {"description": "El recurso no está disponible"},
    },
)
def crear_prestamo(
    prestamo: schemas.PrestamoCreate,
    db: Annotated[Session, Depends(get_db)],
    x_idempotency_key: Annotated[str | None, Header(alias="X-Idempotency-Key")] = None,
):
    return loans_service.crear_prestamo(
        db, prestamo, idempotency_key=x_idempotency_key
    )


@router.get("", response_model=list[schemas.PrestamoOut])
def listar_prestamos(db: Annotated[Session, Depends(get_db)]):
    return loans_service.listar_prestamos(db)
