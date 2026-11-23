"""
Carga masiva de roles (ADR-0024; antes lista de asignación por correo, ADR-0019).

Solo administrador (`usuarios.gestionar`). Sin lógica: delega en app.service.asignaciones
(validación, protección del último administrador y auditoría). Se aplica SOLO a cuentas que ya
existen: nadie recibe un rol por registrarse con un correo.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.middleware.deps import GestionaUsuarios
from app.schemas.asignaciones import ImportarAsignaciones, ResultadoImportacion
from app.service import asignaciones as servicio

router = APIRouter()


@router.post("/importar", response_model=ResultadoImportacion,
             responses={409: {"description": "Dejaría el sistema sin administrador activo"}})
def importar_asignaciones(
    body: ImportarAsignaciones,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Todo o nada: con un error en cualquier línea no se guarda ninguna (`aplicado` = false).
    Con `simular` = true solo devuelve la vista previa."""
    return servicio.importar(db, body.texto, body.simular, current_user)
