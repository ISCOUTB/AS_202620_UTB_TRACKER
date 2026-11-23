"""Indicadores: /stats/resumen (operación, auditor y administrador) y /stats/admin (administrador)."""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.middleware.deps import AdministraSalones, VeEstadisticas
from app.schemas.estadisticas import EstadisticasAdmin
from app.service import estadisticas as estadisticas_service

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/resumen")
def resumen(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
) -> dict[str, int]:
    """Devuelve los contadores operativos usados por el panel principal."""
    return estadisticas_service.resumen_operativo(db)


@router.get("/admin", response_model=EstadisticasAdmin)
def estadisticas_admin(
    db: Annotated[Session, Depends(get_db)],
    current_user: VeEstadisticas,
    dias: Annotated[int, Query(ge=1, le=365)] = 30,
):
    """Estadísticas del administrador: usuarios por rol, solicitudes, salones y reportes."""
    return estadisticas_service.resumen_admin(db, dias)
