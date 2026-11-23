"""
Módulo de dominio: préstamos.

Corte vertical S4 / S9: implementa la regla de negocio central del sistema
(documento de idea, sección 6): "un recurso solo puede prestarse si su
estado es disponible".

LEGADO: desde ADR-0010 los equipos NO se prestan (son fijos en cada salón). Se conserva por
compatibilidad del contrato, pero solo auditor y administrador lo pueden usar (ADR-0018).

Refactorización S9 / S11:
- S9 (req. 9.6): Capa de servicio desacoplada.
- S11 (req. 11.3): Soporte para cabecera de idempotencia 'X-Idempotency-Key'.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Header, Query, Response
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.middleware.deps import GestionaEquipos
from app.schemas import schemas
from app.service import loans as loans_service

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
    current_user: GestionaEquipos,
    x_idempotency_key: Annotated[str | None, Header(alias="X-Idempotency-Key")] = None,
):
    return loans_service.crear_prestamo(
        db, prestamo, idempotency_key=x_idempotency_key
    )


@router.get("", response_model=list[schemas.PrestamoOut])
def listar_prestamos(
    response: Response,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
    estado: Optional[str] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """
    Lista préstamos de recursos (histórico). Solo auditor y administrador (ADR-0018).
    Devuelve el total en el header X-Total-Count.
    """
    items, total = loans_service.listar_prestamos(db, None, estado, skip, limit)
    response.headers["X-Total-Count"] = str(total)
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
    current_user: GestionaEquipos,
):
    """
    Registra la devolución de un préstamo.
    Marca fecha_devolucion_real y restaura el recurso a 'disponible'.
    """
    return loans_service.devolver_prestamo(db, prestamo_id)


@router.post("/marcar-vencidos", response_model=list[schemas.PrestamoOut])
def marcar_vencidos(
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    """Job idempotente para actualizar préstamos activos vencidos."""
    return loans_service.marcar_prestamos_vencidos(db)


@router.post("/jobs/marcar-vencidos", response_model=list[schemas.PrestamoOut], include_in_schema=False)
def marcar_vencidos_job(
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaEquipos,
):
    return loans_service.marcar_prestamos_vencidos(db)
