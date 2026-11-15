"""
Router de auditoría: consulta de la bitácora (solo lectura, solo rol administrador).

No hay endpoints para crear, editar ni borrar registros: los escriben los servicios al ejecutar
cada acción (ver app/services/auditoria.py).
"""
from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import SoloAdministrador
from app.schemas.auditoria import AuditoriaResponse
from app.services import auditoria as service

router = APIRouter()


@router.get("", response_model=list[AuditoriaResponse])
def listar_auditoria(
    db: Annotated[Session, Depends(get_db)],
    current_user: SoloAdministrador,
    accion: Annotated[Optional[str], Query(description="Acción exacta o prefijo (ej. 'salon')")] = None,
    entidad: Optional[str] = None,
    actor_id: Optional[int] = None,
    desde: Optional[datetime] = None,
    hasta: Optional[datetime] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """Bitácora de acciones, de la más reciente a la más antigua."""
    return service.listar(db, accion, entidad, actor_id, desde, hasta, skip, limit)


@router.get("/exportar", response_class=Response)
def exportar_auditoria(
    db: Annotated[Session, Depends(get_db)],
    current_user: SoloAdministrador,
    accion: Optional[str] = None,
    entidad: Optional[str] = None,
    actor_id: Optional[int] = None,
    desde: Optional[datetime] = None,
    hasta: Optional[datetime] = None,
):
    """Descarga la bitácora filtrada en CSV (máx. 5000 filas)."""
    contenido = service.exportar_csv(db, accion, entidad, actor_id, desde, hasta)
    return Response(
        content=contenido,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="auditoria.csv"'},
    )
