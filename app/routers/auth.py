"""
Router del módulo de Autenticación y Usuarios (S8/S9).

Endpoints para registro, login (emisión de JWT), consulta del perfil
del usuario autenticado (GET /auth/me), y gestión de usuarios.
Delega toda la lógica de negocio y hashing seguro (bcrypt) a app.services.auth.
"""
from typing import Annotated, Optional

import time
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.auth import (
    ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest,
    FcmTokenRequest,
    TokenResponse,
    UserMeResponse,
    UserResponse,
    UsuarioCreate,
    UsuarioLogin,
    UsuarioRoleUpdate,
)
from app.services import auth as auth_service

router = APIRouter(prefix="/auth", tags=["auth"])
_login_failures: dict[str, list[float]] = defaultdict(list)


def _client_key(request: Request, username: str) -> str:
    host = request.client.host if request.client else "unknown"
    return f"{host}:{username.strip().lower()}"


@router.post("/login", response_model=TokenResponse)
def login_endpoint(
    user: UsuarioLogin,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
):
    from app.core.config import LOGIN_RATE_LIMIT, LOGIN_RATE_WINDOW_SECONDS
    key = _client_key(request, user.nombre)
    ahora = time.monotonic()
    _login_failures[key] = [
        instante for instante in _login_failures[key]
        if ahora - instante < LOGIN_RATE_WINDOW_SECONDS
    ]
    if len(_login_failures[key]) >= LOGIN_RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Demasiados intentos. Intenta más tarde.")
    try:
        result = auth_service.login(db, user)
    except HTTPException as error:
        if error.status_code == 401:
            _login_failures[key].append(ahora)
        raise
    _login_failures.pop(key, None)
    return result


@router.post("/register", response_model=UserResponse, status_code=201)
def register_endpoint(
    user: UsuarioCreate,
    db: Annotated[Session, Depends(get_db)],
):
    return auth_service.create_user(db, user)


@router.get("/me", response_model=UserMeResponse)
def me_endpoint(current_user: CurrentUser):
    """Retorna los datos del usuario autenticado a partir del token JWT."""
    return current_user


@router.delete("/delete/{user_id}")
def delete_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Elimina (soft-delete) un usuario. Requiere rol admin/auxiliar."""
    return auth_service.delete_user(db, user_id)


@router.get("/user/{user_id}", response_model=UserResponse)
def get_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: CurrentUser,
):
    return auth_service.get_user_by_id(db, user_id)


@router.get("/users", response_model=list[UserResponse])
def get_users_endpoint(
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
    search: Optional[str] = None,
    rol: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
):
    """Lista todos los usuarios para el panel administrativo. Requiere rol admin/auxiliar."""
    return auth_service.get_all_users(
        db, skip=skip, limit=limit, search=search, rol=rol
    )


@router.patch("/user/{user_id}/role", response_model=UserResponse)
@router.put("/user/{user_id}/role", response_model=UserResponse)
def update_user_role_endpoint(
    user_id: int,
    body: UsuarioRoleUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: AdminUser,
):
    """Asigna o actualiza el rol de un usuario desde el panel administrativo. Requiere rol admin/auxiliar."""
    return auth_service.update_user_role(db, user_id, body.rol)


@router.post("/forgot-password", status_code=202)
def forgot_password_endpoint(
    body: ForgotPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    auth_service.request_password_reset(db, body.email)
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
