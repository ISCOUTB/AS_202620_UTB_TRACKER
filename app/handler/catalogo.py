"""
Router del catálogo de salones UTB (ADR-0021). Solo Administrador.

Prefijo /salones/catalogo: se registra ANTES que los routers de salones para que
`/salones/catalogo/...` no se lea como `/salones/{salon_id}/...`.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.middleware.deps import GestionaCatalogo
from app.schemas.catalogo import (
    RangoCatalogo,
    ResultadoRango,
    SalonFueraCatalogo,
    VistaPreviaRango,
)
from app.service import catalogo as service

router = APIRouter()


@router.post("/rango/vista-previa", response_model=VistaPreviaRango)
def vista_previa_rango(
    datos: RangoCatalogo,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaCatalogo,
):
    """Qué salones crearía el rango y cuáles ya existen. No escribe nada."""
    return service.vista_previa_rango(db, datos.edificio, datos.piso, datos.desde, datos.hasta)


@router.post("/rango", response_model=ResultadoRango, status_code=201)
def crear_rango(
    datos: RangoCatalogo,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaCatalogo,
):
    """Crea los salones del rango que falten (los existentes no se tocan). Auditado."""
    return service.crear_rango(
        db, datos.edificio, datos.piso, datos.desde, datos.hasta,
        datos.capacidad, datos.tipo.value, actor_id=current_user.id,
    )


@router.get("/fuera", response_model=list[SalonFueraCatalogo])
def salones_fuera_del_catalogo(
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaCatalogo,
):
    """Salones activos que no siguen la regla o no están en el catálogo, con una propuesta.
    Solo informa: nada se borra ni se cambia."""
    return service.fuera_del_catalogo(db)
