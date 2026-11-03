"""Indicadores resumidos para el dashboard."""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser
from app.models.recurso_models import Prestamo, Recurso, Reporte
from app.models.salon_models import PrestamoSalon, Salon

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/resumen")
def resumen(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
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
