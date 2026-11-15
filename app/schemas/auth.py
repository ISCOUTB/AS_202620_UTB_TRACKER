"""
Schemas Pydantic para el módulo de autenticación y usuarios.

Mejoras aplicadas:
- Validación de longitud mínima para contraseña.
- Schema UserMeResponse para GET /auth/me.
- TokenResponse incluye datos del usuario al hacer login.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.core.politica import (
    MSG_CORREO_INVALIDO,
    PASSWORD_MINIMO,
    correo_valido,
    error_password,
    normalizar_correo,
    normalizar_nombre,
)


def _correo(v: str) -> str:
    v = normalizar_correo(v)
    if not correo_valido(v):
        raise ValueError(MSG_CORREO_INVALIDO)
    return v


class UsuarioCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., min_length=5, max_length=254)
    rol: str = Field(default="usuario_utb")
    password: str = Field(..., min_length=PASSWORD_MINIMO, max_length=128)

    _nombre = field_validator("nombre")(lambda v: normalizar_nombre(v))
    _email = field_validator("email")(_correo)

    @model_validator(mode="after")
    def _politica(self):
        error = error_password(self.password, self.email, self.nombre)
        if error:
            raise ValueError(error)
        return self


class UsuarioRoleUpdate(BaseModel):
    """Esquema para asignar o actualizar el rol desde el panel administrativo."""
    rol: str = Field(
        ...,
        min_length=3,
        max_length=50,
        description="Nuevo rol: usuario_utb, auxiliar, administrador",
    )


class UsuarioLogin(BaseModel):
    # Se llama "nombre" por compatibilidad con el contrato, pero acepta el nombre de usuario
    # O el correo (ADR-0014).
    nombre: str = Field(..., description="Nombre de usuario o correo")
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    refresh_token: Optional[str] = None
    user: Optional["UserMeResponse"] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    fecha_registro: datetime
    rol: str
    email_verificado: bool = True


class UserMeResponse(BaseModel):
    """Respuesta para GET /auth/me — datos del usuario autenticado."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    rol: str
    # Campo nuevo con valor por defecto: no rompe el contrato (ADR-0014).
    email_verificado: bool = True


class UsuarioDelete(BaseModel):
    nombre: str
    id: int


class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=254)

    _email = field_validator("email")(lambda v: normalizar_correo(v))


class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10)
    new_password: str = Field(..., min_length=PASSWORD_MINIMO, max_length=128)


class CambiarCorreoRequest(BaseModel):
    correo_nuevo: str = Field(..., min_length=5, max_length=254)
    password: str = Field(..., min_length=1, max_length=128, description="Contraseña actual")


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., min_length=20)


class FcmTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=4096)
