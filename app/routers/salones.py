"""
Router del módulo de Salones.

CRUD completo de salones con control de acceso y consulta de disponibilidad.
Endpoints protegidos con JWT; operaciones de escritura requieren rol admin/auxiliar.
"""
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdministraSalones, GestionaCatalogo, VeSalones
from app.schemas.enums import CategoriaRecurso, TipoSalon
from app.schemas.salones import SalonCreate, SalonResponse, SalonUpdate
from app.services import salones as salones_service

router = APIRouter()


@router.post("", response_model=SalonResponse, status_code=201)
def crear_salon(
    salon: SalonCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaCatalogo,
):
    """Crea un salón del catálogo (solo Administrador, ADR-0021). Valida el código A1-101."""
    return salones_service.crear_salon(db, salon, actor_id=current_user.id)


@router.get("", response_model=list[SalonResponse])
def listar_salones(
    db: Annotated[Session, Depends(get_db)],
    current_user: VeSalones,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 100,  # 100: una APK vieja (sin paginar) ve todo el catálogo UTB
    estado: Optional[str] = None,
    edificio: Optional[str] = None,
    piso: Annotated[Optional[int], Query(ge=0, le=99)] = None,
    busqueda: Annotated[Optional[str], Query(description="Busca en nombre y descripción")] = None,
    tipo: Optional[TipoSalon] = None,
    con_equipo: Annotated[
        Optional[CategoriaRecurso],
        Query(description="Solo salones con al menos un equipo operativo de esta categoría"),
    ] = None,
):
    """Lista salones con filtros opcionales, paginación y equipamiento calculado."""
    items, _ = salones_service.listar_salones(
        db, skip, limit, estado, edificio, busqueda,
        tipo=tipo.value if tipo else None,
        con_equipo=con_equipo.value if con_equipo else None,
        piso=piso,
    )
    return items


@router.get("/{salon_id}", response_model=SalonResponse)
def obtener_salon(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: VeSalones,
):
    """Obtiene un salón por ID, con su equipamiento y tipo sugerido."""
    return salones_service.obtener_salon_con_equipamiento(db, salon_id)


@router.put("/{salon_id}", response_model=SalonResponse)
def actualizar_salon(
    salon_id: int,
    salon: SalonUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdministraSalones,
):
    """Actualiza un salón. Auditor y Administrador; renombrar o mover de edificio/piso solo el
    Administrador (ADR-0021)."""
    return salones_service.actualizar_salon(
        db, salon_id, salon, actor_id=current_user.id, actor_rol=current_user.rol
    )


@router.delete("/{salon_id}")
def eliminar_salon(
    salon_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaCatalogo,
):
    """Desactiva un salón del catálogo (nunca se borra: conserva su historial). Solo Administrador."""
    return salones_service.eliminar_salon(db, salon_id, actor_id=current_user.id)


@router.get("/{salon_id}/disponibilidad")
def obtener_disponibilidad(
    salon_id: int,
    dia_semana: Annotated[int, Query(ge=1, le=7, description="1=Lunes, 7=Domingo")],
    db: Annotated[Session, Depends(get_db)],
    current_user: VeSalones,
    fecha: Optional[date] = None,
):
    """
    Consulta las franjas horarias disponibles de un salón en un día dado.
    Cruza los horarios académicos fijos con los préstamos de salón existentes.
    """
    return salones_service.obtener_disponibilidad(db, salon_id, dia_semana, fecha)
