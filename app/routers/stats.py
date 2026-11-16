"""Indicadores: /stats/resumen (operación, auditor y administrador) y /stats/admin (administrador)."""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdministraSalones, VeEstadisticas
from app.models.recurso_models import Prestamo, Recurso, Reporte
from app.models.salon_models import PrestamoSalon, Salon
from app.schemas.estadisticas import EstadisticasAdmin
from app.services import estadisticas as estadisticas_service

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/resumen")
def resumen(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
) -> dict[str, int]:
    """Devuelve los contadores operativos usados por el panel principal."""
    return {
        "salones_libres": db.query(func.count(Salon.id)).filter(
            Salon.activo.is_(True), Salon.estado == "disponible"
        ).scalar() or 0,
        "salones_ocupados": db.query(func.count(Salon.id)).filter(
            Salon.activo.is_(True), Salon.estado == "ocupado"
        ).scalar() or 0,
        "equipos_disponibles": db.query(func.count(Recurso.id)).filter(
            Recurso.activo.is_(True), Recurso.estado == "disponible"
        ).scalar() or 0,
        "prestamos_activos": db.query(func.count(Prestamo.id)).filter(
            Prestamo.estado == "activo"
        ).scalar() or 0,
        "reportes_abiertos": db.query(func.count(Reporte.id)).filter(
            Reporte.estado_reportado.in_(["dañado", "abierto"])
        ).scalar() or 0,
        "solicitudes_salon_pendientes": db.query(func.count(PrestamoSalon.id)).filter(
            PrestamoSalon.estado == "pendiente"
        ).scalar() or 0,
    }


@router.get("/admin", response_model=EstadisticasAdmin)
def estadisticas_admin(
    db: Annotated[Session, Depends(get_db)],
    current_user: VeEstadisticas,
    dias: Annotated[int, Query(ge=1, le=365)] = 30,
):
    """Estadísticas del administrador: usuarios por rol, solicitudes, salones y reportes."""
    return estadisticas_service.resumen_admin(db, dias)
