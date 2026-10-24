"""
Router del módulo de Autenticación y Usuarios (S8/S9).

Endpoints para registro, login (emisión de JWT), consulta del perfil
del usuario autenticado (GET /auth/me), y gestión de usuarios.
Delega toda la lógica de negocio y hashing seguro (bcrypt) a app.services.auth.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import AdminUser, CurrentUser
from app.schemas.auth import TokenResponse, UserMeResponse, UserResponse, UsuarioCreate, UsuarioLogin
from app.services import auth as auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login_endpoint(
    user: UsuarioLogin,
    db: Annotated[Session, Depends(get_db)],
):
    return auth_service.login(db, user)


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
