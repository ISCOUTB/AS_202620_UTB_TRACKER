"""
Router de administración de salones (panel del auxiliar).

Se registra ANTES que el router de salones para que `/salones/ocupacion`
no sea interpretado como `/salones/{salon_id}`.
"""
from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.enums import EstadoReporteSalon
from app.schemas.salones_admin import (
    OcupacionSalon,
    PresenciaResponse,
    PresenciaUpdate,
    ReporteSalonCreate,
    ReporteSalonResponse,
    ReporteSalonUpdate,
)
from app.services import salones_admin as service

router = APIRouter()

MomentoQuery = Annotated[
    Optional[datetime],
    Query(description="Hora local del campus a consultar (por defecto, ahora). Útil para pruebas."),
]


@router.get("/ocupacion", response_model=list[OcupacionSalon])
def listar_ocupacion(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
    momento: MomentoQuery = None,
):
    """Estado en vivo de todos los salones: quién los tiene y si el profesor llegó."""
    return service.listar_ocupacion(db, momento)


@router.get("/{salon_id}/ocupacion", response_model=OcupacionSalon)
def obtener_ocupacion(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
    momento: MomentoQuery = None,
):
    return service.obtener_ocupacion(db, salon_id, momento)


@router.put(
    "/{salon_id}/presencia",
    response_model=PresenciaResponse,
    responses={409: {"description": "No hay una clase en curso en este salón"}},
)
def registrar_presencia(
    salon_id: int,
    datos: PresenciaUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
    momento: MomentoQuery = None,
):
    """Confirma o desmiente que el profesor llegó a la clase en curso."""
    return service.registrar_presencia(db, salon_id, datos, current_user.id, momento)


@router.post("/{salon_id}/reportes", response_model=ReporteSalonResponse, status_code=201)
def crear_reporte(
    salon_id: int,
    datos: ReporteSalonCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    return service.crear_reporte(db, salon_id, datos, current_user.id)


@router.get("/{salon_id}/reportes", response_model=list[ReporteSalonResponse])
def listar_reportes(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
    estado: Optional[EstadoReporteSalon] = None,
):
    return service.listar_reportes(db, salon_id, estado.value if estado else None)


@router.patch("/{salon_id}/reportes/{reporte_id}", response_model=ReporteSalonResponse)
def actualizar_reporte(
    salon_id: int,
    reporte_id: int,
    datos: ReporteSalonUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Marca un reporte como resuelto (o lo reabre). Solo auxiliar/administrador."""
    return service.actualizar_estado_reporte(db, salon_id, reporte_id, datos.estado)
