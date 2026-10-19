"""
Router del módulo de Autenticación y Usuarios (S8/S9).

Endpoints para registro, login (emisión de JWT), consulta y eliminación de usuarios.
Delega toda la lógica de negocio y hashing seguro (bcrypt) a app.services.auth.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.auth import TokenResponse, UserResponse, UsuarioCreate, UsuarioLogin
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


@router.delete("/delete/{user_id}")
def delete_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
):
    return auth_service.delete_user(db, user_id)


@router.get("/user/{user_id}", response_model=UserResponse)
def get_user_endpoint(
    user_id: int,
    db: Annotated[Session, Depends(get_db)],
):
    return auth_service.get_user_by_id(db, user_id)
