"""
Schemas Pydantic para el módulo de autenticación y usuarios.

Mejoras aplicadas:
- Validación de longitud mínima para contraseña.
- Schema UserMeResponse para GET /auth/me.
- TokenResponse incluye datos del usuario al hacer login.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class UsuarioCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., min_length=5)
    rol: str = Field(default="usuario_utb")
    password: str = Field(..., min_length=6)


class UsuarioLogin(BaseModel):
    nombre: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: Optional["UserMeResponse"] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    fecha_registro: datetime
    rol: str


class UserMeResponse(BaseModel):
    """Respuesta para GET /auth/me — datos del usuario autenticado."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    rol: str


class UsuarioDelete(BaseModel):
    nombre: str
    id: int