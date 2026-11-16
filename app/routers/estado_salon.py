"""
Router de la habilitación de salones (ADR-0022). Auditor y Administrador.

Prefijo /salones: se registra ANTES que los demás routers de salones para que las rutas fijas
(`/habilitacion/lote`, `/ocupacion/resumen`, `/exportar.csv`) no se lean como `/{salon_id}`.
"""
from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdministraSalones
from app.schemas.estado_salon import (
    HabilitacionLote,
    HabilitacionResultado,
    HabilitacionUpdate,
    HistorialSalonResponse,
    ResumenPiso,
    VistaPreviaLote,
)
from app.services import estado_salon as service
from app.services import exportar
from app.services import salones as salones_service

router = APIRouter()


def _lote(datos: HabilitacionLote) -> tuple:
    return (datos.edificio.strip().upper(), datos.piso, datos.habilitado)


@router.post("/habilitacion/lote/vista-previa", response_model=VistaPreviaLote)
def vista_previa_lote(
    datos: HabilitacionLote,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Qué salones cambiarían y cuántas solicitudes quedarían afectadas. No escribe nada."""
    return service.vista_previa_lote(db, *_lote(datos))


@router.post("/habilitacion/lote", response_model=VistaPreviaLote)
def aplicar_lote(
    datos: HabilitacionLote,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Habilita o deshabilita un edificio o un piso completo (todo o nada). Auditado."""
    edificio, piso, habilitado = _lote(datos)
    return service.aplicar_lote(
        db, edificio, piso, habilitado, datos.motivo.value if datos.motivo else None,
        datos.nota, datos.reapertura_estimada, actor_id=current_user.id,
    )


@router.get("/ocupacion/resumen", response_model=list[ResumenPiso])
def resumen_ocupacion(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
    momento: Annotated[Optional[datetime], Query(description="Hora local del campus")] = None,
):
    """Cuántos salones hay libres, ocupados y deshabilitados AHORA por edificio y piso."""
    return service.resumen_por_piso(db, momento)


@router.get("/exportar.csv", response_class=Response,
            responses={200: {"content": {"text/csv": {}}}})
def exportar_catalogo(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Catálogo de salones y sus equipos en CSV (para revisar con Planta Física)."""
    return Response(
        content=exportar.catalogo_csv(db),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="catalogo_salones.csv"'},
    )


@router.patch("/{salon_id}/habilitacion", response_model=HabilitacionResultado)
def cambiar_habilitacion(
    salon_id: int,
    datos: HabilitacionUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Habilita o deshabilita UN salón (motivo obligatorio al deshabilitar). Auditado."""
    salon = salones_service.obtener_salon(db, salon_id)
    afectadas = service.cambiar_habilitacion(
        db, salon, datos.habilitado, datos.motivo.value if datos.motivo else None,
        datos.nota, datos.reapertura_estimada, actor_id=current_user.id,
    )
    return {"salon": salones_service.obtener_salon_con_equipamiento(db, salon_id),
            "solicitudes_afectadas": afectadas}


@router.get("/{salon_id}/historial", response_model=list[HistorialSalonResponse])
def historial(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Últimos cambios de habilitación y de equipos del salón (lo más reciente primero)."""
    salones_service.obtener_salon(db, salon_id)
    return service.historial(db, salon_id)
