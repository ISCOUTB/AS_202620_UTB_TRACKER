"""
Router de gestión de usuarios (solo administrador, ADR-0018).

Sin lógica: valida la entrada y delega en app.services.usuarios (reglas del último
administrador, cambios sobre uno mismo, invalidación de sesiones y auditoría).
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser, GestionaUsuarios
from app.schemas.usuarios import CambioEstado, CambioRol, UsuarioAdmin
from app.routers.fotos import respuesta_foto
from app.services import fotos as fotos_service
from app.services import usuarios as usuarios_service

router = APIRouter()


@router.get("", response_model=list[UsuarioAdmin])
def listar_usuarios(
    response: Response,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
    busqueda: Optional[str] = None,
    rol: Annotated[Optional[str], Query(description="usuario_utb | auxiliar | administrador")] = None,
    activo: Optional[bool] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """Usuarios con búsqueda, filtro por rol y su última actividad. Total en X-Total-Count."""
    filas, total = usuarios_service.listar(db, busqueda, rol, activo, skip, limit)
    response.headers["X-Total-Count"] = str(total)
    return [UsuarioAdmin.de(u, en, version) for u, en, version in filas]


@router.patch("/{usuario_id}/rol", response_model=UsuarioAdmin)
def cambiar_rol(
    usuario_id: int,
    body: CambioRol,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Cambia el rol. 409 sobre uno mismo o si dejaría el sistema sin administrador."""
    return UsuarioAdmin.de(usuarios_service.cambiar_rol(db, usuario_id, body.rol, current_user))


@router.patch("/{usuario_id}/estado", response_model=UsuarioAdmin)
def cambiar_estado(
    usuario_id: int,
    body: CambioEstado,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Activa o desactiva la cuenta. Mismas protecciones que el cambio de rol."""
    return UsuarioAdmin.de(
        usuarios_service.cambiar_estado(db, usuario_id, body.activo, current_user)
    )


@router.get("/{usuario_id}/foto", response_class=Response,
            responses={200: {"content": {"image/jpeg": {}, "image/png": {}}},
                       403: {"description": "Foto de otra persona sin permiso"},
                       404: {"description": "Sin foto"}})
def foto_de_usuario(
    usuario_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """La propia, o la de otra persona con `usuarios.ver` (listas de auditor/administrador)."""
    return respuesta_foto(fotos_service.obtener(db, usuario_id, current_user))
