"""
Router del módulo de Autenticación y Usuarios (S8/S9).

Endpoints para registro, login (emisión de JWT), consulta del perfil
del usuario autenticado (GET /auth/me), y gestión de usuarios.
Delega toda la lógica de negocio y hashing seguro (bcrypt) a app.services.auth.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Request, Response
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.core import permisos as permisos_core
from app.core.database import get_db
from app.core.deps import CurrentUser, GestionaUsuarios
from app.schemas.auth import (
    CambiarCorreoRequest,
    ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest,
    FcmTokenRequest,
    TokenResponse,
    UserResponse,
    UsuarioCreate,
    UsuarioLogin,
    UsuarioRoleUpdate,
)
from app.routers.fotos import leer_cuerpo_limitado, respuesta_foto
from app.schemas.perfil import (
    CambiarPasswordRequest,
    FotoEstado,
    PasswordRequest,
    PerfilResponse,
    PerfilUpdate,
    RolCatalogo,
    SesionRenovada,
)
from app.services import auth as auth_service
from app.services import fotos as fotos_service
from app.services import paginas_auth, perfil as perfil_service
from app.services import usuarios as usuarios_service

router = APIRouter(prefix="/auth", tags=["auth"])

_SEGURIDAD_HTML = {
    "Content-Security-Policy": paginas_auth.CSP,
    "Cache-Control": "no-store",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
}


def _ip(request: Request) -> str:
    return request.client.host if request.client else "desconocida"


def _html(contenido: str, status_code: int = 200) -> HTMLResponse:
    return HTMLResponse(contenido, status_code=status_code, headers=_SEGURIDAD_HTML)


@router.post(
    "/login",
    response_model=TokenResponse,
    responses={429: {"description": "Demasiados intentos de inicio de sesión"}},
)
def login_endpoint(
    user: UsuarioLogin,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
):
    """Entra con nombre de usuario o correo. Límite de intentos guardado en la base."""
    return auth_service.login(db, user, ip=_ip(request))


@router.post("/register", response_model=UserResponse, status_code=201)
def register_endpoint(
    user: UsuarioCreate,
    db: Annotated[Session, Depends(get_db)],
):
    """Crea la cuenta (solo correos institucionales). Siempre nace como Estudiante (ADR-0024)."""
    return auth_service.create_user(db, user)


@router.get("/restablecer", response_class=HTMLResponse)
def restablecer_pagina_endpoint(
    token: Annotated[str, Query(min_length=10, max_length=2048)],
):
    """Página del enlace de recuperación: formulario que llama a POST /auth/reset-password."""
    return _html(paginas_auth.formulario_restablecer(token))


@router.get("/roles", response_model=list[RolCatalogo])
def roles_endpoint(current_user: CurrentUser):
    """Catálogo de roles con etiqueta, descripción y permisos (la matriz única, ADR-0025). La app
    lo usa para el modo prueba y para listar roles: no tiene copia propia de la tabla."""
    return permisos_core.catalogo()


@router.get("/me", response_model=PerfilResponse)
def me_endpoint(current_user: CurrentUser, db: Annotated[Session, Depends(get_db)]):
    """Perfil completo: datos, preferencias y, desde ADR-0018, `rol_etiqueta` y
    `permisos` (la app decide qué mostrar por permisos, nunca comparando el texto del rol).
    Desde ADR-0019: `correo_institucional`, `rol_origen`, `rol_origen_texto` y `cargo`."""
    return perfil_service.respuesta(db, current_user)


@router.patch("/me", response_model=PerfilResponse)
def actualizar_perfil_endpoint(
    body: PerfilUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Edita nombre para mostrar, teléfono, dependencia/cargo, color de avatar y preferencias."""
    return perfil_service.respuesta(db, perfil_service.actualizar_perfil(db, current_user, body))


_CUERPO_FOTO = {
    "requestBody": {
        "required": True,
        "description": "Los bytes de la foto (JPEG o PNG, ya reducida por la app). El tipo se "
                       "decide por el contenido, no por el Content-Type.",
        "content": {t: {"schema": {"type": "string", "format": "binary"}}
                    for t in ("image/jpeg", "image/png")},
    }
}


@router.put("/me/foto", response_model=FotoEstado, openapi_extra=_CUERPO_FOTO,
            responses={413: {"description": "Demasiado grande"},
                       415: {"description": "No es JPEG ni PNG"},
                       422: {"description": "Dañada o de dimensiones no admitidas"},
                       429: {"description": "Demasiadas subidas"}})
async def subir_foto_endpoint(
    request: Request,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Sube o reemplaza la foto propia (ADR-0020). Se quitan sus metadatos (EXIF/GPS)."""
    datos = await leer_cuerpo_limitado(request)
    foto = await run_in_threadpool(fotos_service.guardar, db, current_user, datos)
    return FotoEstado(tiene_foto=True, foto_version=foto.version, tipo=foto.tipo,
                      tamano=foto.tamano, ancho=foto.ancho, alto=foto.alto)


@router.delete("/me/foto", response_model=FotoEstado)
def quitar_foto_endpoint(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Quita la foto propia: el contenido se borra de la base."""
    fotos_service.quitar(db, current_user)
    return FotoEstado(tiene_foto=False)


@router.get("/me/foto", response_class=Response,
            responses={200: {"content": {"image/jpeg": {}, "image/png": {}}},
                       404: {"description": "Sin foto"}})
def ver_mi_foto_endpoint(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    return respuesta_foto(fotos_service.obtener(db, current_user.id, current_user))


@router.post("/me/cambiar-password", response_model=SesionRenovada,
             responses={403: {"description": "Contraseña actual incorrecta"}})
def cambiar_password_endpoint(
    body: CambiarPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Cambia la contraseña y cierra las demás sesiones; devuelve tokens para este dispositivo."""
    return perfil_service.cambiar_password(db, current_user, body.password_actual, body.password_nueva)


@router.post("/me/cerrar-sesiones", response_model=SesionRenovada)
def cerrar_sesiones_endpoint(
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Cierra la sesión en todos los demás dispositivos."""
    return perfil_service.cerrar_sesiones(db, current_user)


@router.post("/me/desactivar", status_code=200,
             responses={403: {"description": "Contraseña actual incorrecta"}})
def desactivar_cuenta_endpoint(
    body: PasswordRequest,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Desactiva la cuenta propia (confirmando con la contraseña). Un administrador puede reactivarla."""
    perfil_service.desactivar_cuenta(db, current_user, body.password)
    return {"message": "Tu cuenta quedó desactivada."}


@router.post("/me/cambiar-correo", response_model=PerfilResponse,
             responses={403: {"description": "Contraseña actual incorrecta"},
                        409: {"description": "Correo en uso"}, 429: {"description": "Límite"}})
def cambiar_correo_endpoint(
    body: CambiarCorreoRequest,
    request: Request,
    current_user: CurrentUser,
    db: Annotated[Session, Depends(get_db)],
):
    """Cambia el correo al instante (solo institucional) confirmando con la contraseña."""
    user = perfil_service.cambiar_correo(
        db, current_user, body.correo_nuevo, body.password, ip=_ip(request)
    )
    return perfil_service.respuesta(db, user)


@router.delete("/delete/{user_id}")
def delete_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Desactiva (soft-delete) un usuario. Solo administrador (ADR-0018)."""
    return auth_service.delete_user(db, user_id, current_user)


@router.get("/user/{user_id}", response_model=UserResponse)
def get_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Uno mismo, o auditor/administrador (para mostrar quién pidió o reportó)."""
    return usuarios_service.ver_usuario(db, user_id, current_user)


@router.get("/users", response_model=list[UserResponse])
def get_users_endpoint(
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
    search: Optional[str] = None,
    rol: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
):
    """Lista usuarios (legado; la app nueva usa GET /usuarios). Solo administrador."""
    return auth_service.get_all_users(
        db, skip=skip, limit=limit, search=search, rol=rol
    )


@router.patch("/user/{user_id}/role", response_model=UserResponse)
@router.put("/user/{user_id}/role", response_model=UserResponse)
def update_user_role_endpoint(
    user_id: int,
    body: UsuarioRoleUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: GestionaUsuarios,
):
    """Cambia el rol (legado; la app nueva usa PATCH /usuarios/{id}/rol). Solo administrador."""
    return auth_service.update_user_role(db, user_id, body.rol, current_user)


@router.post("/forgot-password", status_code=202)
def forgot_password_endpoint(
    body: ForgotPasswordRequest,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
):
    auth_service.request_password_reset(db, body.email, ip=_ip(request))
    return {"message": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña"}


@router.post("/reset-password")
def reset_password_endpoint(
    body: ResetPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    auth_service.reset_password(db, body.token, body.new_password)
    return {"message": "Contraseña actualizada correctamente"}


@router.post("/refresh", response_model=TokenResponse)
def refresh_endpoint(
    body: RefreshTokenRequest,
    db: Annotated[Session, Depends(get_db)],
):
    return auth_service.refresh_access_token(db, body.refresh_token)


@router.patch("/fcm-token", status_code=204)
def update_fcm_token_endpoint(
    body: FcmTokenRequest,
    current_user: CurrentUser,
    db: Annotated[Session, Depends(get_db)],
):
    auth_service.update_fcm_token(db, current_user, body.fcm_token)
