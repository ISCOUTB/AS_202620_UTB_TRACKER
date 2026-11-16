"""
Router del módulo de Autenticación y Usuarios (S8/S9).

Endpoints para registro, login (emisión de JWT), consulta del perfil
del usuario autenticado (GET /auth/me), y gestión de usuarios.
Delega toda la lógica de negocio y hashing seguro (bcrypt) a app.services.auth.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

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
from app.schemas.perfil import (
    CambiarPasswordRequest,
    PasswordRequest,
    PerfilResponse,
    PerfilUpdate,
    SesionRenovada,
)
from app.services import auth as auth_service
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
    """Crea la cuenta SIN verificar y envía el correo de verificación."""
    return auth_service.create_user(db, user)


@router.get("/verificar-correo", response_class=HTMLResponse, include_in_schema=True)
def verificar_correo_endpoint(
    db: Annotated[Session, Depends(get_db)],
    token: Annotated[str, Query(min_length=10, max_length=2048)],
):
    """Abre el enlace del correo: verifica la cuenta o confirma el cambio de correo."""
    try:
        resultado = auth_service.abrir_enlace_correo(db, token)
    except HTTPException as exc:
        return _html(paginas_auth.enlace_invalido(str(exc.detail)), status_code=400)
    tipo, user = resultado
    if tipo == "cambio":
        return _html(paginas_auth.correo_cambiado(user.email))
    return _html(paginas_auth.correo_verificado(user.nombre))


@router.post("/reenviar-verificacion", status_code=202,
             responses={409: {"description": "Ya verificado"}, 429: {"description": "Límite"}})
def reenviar_verificacion_endpoint(
    request: Request,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    auth_service.reenviar_verificacion(db, current_user, ip=_ip(request))
    return {"message": "Te enviamos de nuevo el correo de verificación."}


@router.get("/restablecer", response_class=HTMLResponse)
def restablecer_pagina_endpoint(
    token: Annotated[str, Query(min_length=10, max_length=2048)],
):
    """Página del enlace de recuperación: formulario que llama a POST /auth/reset-password."""
    return _html(paginas_auth.formulario_restablecer(token))


@router.get("/me", response_model=PerfilResponse)
def me_endpoint(current_user: CurrentUser):
    """Perfil completo: datos, verificación, preferencias y, desde ADR-0018, `rol_etiqueta` y
    `permisos` (la app decide qué mostrar por permisos, nunca comparando el texto del rol)."""
    return current_user


@router.patch("/me", response_model=PerfilResponse)
def actualizar_perfil_endpoint(
    body: PerfilUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Edita nombre para mostrar, teléfono, dependencia/cargo, color de avatar y preferencias."""
    return perfil_service.actualizar_perfil(db, current_user, body)


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


@router.post("/me/cambiar-correo", status_code=202,
             responses={403: {"description": "Contraseña actual incorrecta"},
                        409: {"description": "Correo en uso"}, 429: {"description": "Límite"}})
def cambiar_correo_endpoint(
    body: CambiarCorreoRequest,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    """Pide cambiar el correo: no cambia hasta abrir el enlace enviado al correo NUEVO."""
    perfil_service.solicitar_cambio_correo(
        db, current_user, body.correo_nuevo, body.password, ip=_ip(request)
    )
    return {"message": "Te enviamos un enlace al nuevo correo. Hasta que lo abras, sigue valiendo el anterior."}


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
