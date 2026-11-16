"""
Router de la lista de asignación de roles por correo institucional (ADR-0019).

Solo administrador (`usuarios.gestionar`). Sin lógica: delega en app.services.asignaciones
(validación, protección del último administrador, recálculo inmediato y auditoría).
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import GestionaUsuarios
from app.schemas.asignaciones import (
    AsignacionCrear,
    AsignacionEditar,
    AsignacionRespuesta,
    ImportarAsignaciones,
    ResultadoImportacion,
)
from app.services import asignaciones as servicio

router = APIRouter()


@router.get("", response_model=list[AsignacionRespuesta])
def listar_asignaciones(
    response: Response,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
    busqueda: Optional[str] = None,
    rol: Optional[str] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """Busca por correo o cargo. Total en X-Total-Count."""
    filas, total = servicio.listar(db, busqueda, rol, skip, limit)
    response.headers["X-Total-Count"] = str(total)
    return filas


@router.post("", response_model=AsignacionRespuesta, status_code=201,
             responses={409: {"description": "Ya existe o dejaría sin administrador"}})
def crear_asignacion(
    body: AsignacionCrear,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    return servicio.crear(db, body.correo, body.rol, body.cargo, current_user)


@router.post("/importar", response_model=ResultadoImportacion)
def importar_asignaciones(
    body: ImportarAsignaciones,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Todo o nada: con un error en cualquier línea no se guarda ninguna (`aplicado` = false)."""
    return servicio.importar(db, body.texto, body.simular, current_user)


@router.patch("/{asignacion_id}", response_model=AsignacionRespuesta)
def editar_asignacion(
    asignacion_id: int,
    body: AsignacionEditar,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    return servicio.editar(db, asignacion_id, body.model_dump(exclude_unset=True), current_user)


@router.delete("/{asignacion_id}", status_code=204)
def eliminar_asignacion(
    asignacion_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    servicio.eliminar(db, asignacion_id, current_user)
