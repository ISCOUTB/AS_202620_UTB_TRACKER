"""
Schemas del perfil propio y de las preferencias guardadas en el servidor (ADR-0016).

Las preferencias tienen valores por defecto: una cuenta sin preferencias guardadas (NULL) se
comporta igual que una con todo encendido y texto normal.
"""
import re
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.politica import PASSWORD_MINIMO, normalizar_nombre

TamanoTexto = Literal["normal", "grande", "extra_grande"]
PantallaInicio = Literal["inicio", "salones", "control"]

# Tipos de notificación que el usuario puede apagar. "seguridad" no está: siempre se envía.
CATEGORIAS = ("cuenta", "salones")
CANALES = ("correo", "push")


class Canal(BaseModel):
    model_config = ConfigDict(extra="ignore")

    cuenta: bool = True    # bienvenida y novedades de la cuenta
    salones: bool = True   # solicitudes de salón aprobadas/rechazadas, recordatorios


class Notificaciones(BaseModel):
    model_config = ConfigDict(extra="ignore")

    correo: Canal = Field(default_factory=Canal)
    push: Canal = Field(default_factory=Canal)


class Preferencias(BaseModel):
    model_config = ConfigDict(extra="ignore")

    notificaciones: Notificaciones = Field(default_factory=Notificaciones)
    tamano_texto: TamanoTexto = "normal"
    # Útil al auxiliar: abrir la app directamente en Salones o en Control.
    pantalla_inicio: PantallaInicio = "inicio"

    @classmethod
    def de(cls, valor: Optional[dict]) -> "Preferencias":
        return cls.model_validate(valor or {})


class PerfilResponse(BaseModel):
    """GET /auth/me: perfil completo. Los campos nuevos tienen valor por defecto (contrato)."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    rol: str
    email_verificado: bool = True
    fecha_registro: Optional[datetime] = None
    nombre_mostrar: Optional[str] = None
    telefono: Optional[str] = None
    dependencia: Optional[str] = None
    color_avatar: Optional[str] = None
    preferencias: Preferencias = Field(default_factory=Preferencias)

    @field_validator("preferencias", mode="before")
    @classmethod
    def _defecto(cls, v):
        return Preferencias.de(v if isinstance(v, dict) else None)


_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")
_TELEFONO = re.compile(r"^[0-9+()\- ]{7,20}$")


class PerfilUpdate(BaseModel):
    """PATCH /auth/me: solo se cambian los campos enviados. "" borra un campo opcional."""
    model_config = ConfigDict(extra="forbid")

    nombre_mostrar: Optional[str] = Field(None, max_length=100)
    telefono: Optional[str] = Field(None, max_length=20)
    dependencia: Optional[str] = Field(None, max_length=120)
    color_avatar: Optional[str] = Field(None, max_length=7)
    preferencias: Optional[Preferencias] = None

    @field_validator("nombre_mostrar", "dependencia")
    @classmethod
    def _texto(cls, v):
        return None if v is None else normalizar_nombre(v)

    @field_validator("telefono")
    @classmethod
    def _telefono(cls, v):
        if v is None or v.strip() == "":
            return v if v is None else ""
        if not _TELEFONO.match(v.strip()):
            raise ValueError("Teléfono inválido: usa solo números, espacios, +, - o paréntesis")
        return v.strip()

    @field_validator("color_avatar")
    @classmethod
    def _color(cls, v):
        if v is None or v == "":
            return v
        if not _COLOR.match(v):
            raise ValueError("Color inválido: usa el formato #RRGGBB")
        return v.upper()


class CambiarPasswordRequest(BaseModel):
    password_actual: str = Field(..., min_length=1, max_length=128)
    password_nueva: str = Field(..., min_length=PASSWORD_MINIMO, max_length=128)


class PasswordRequest(BaseModel):
    """Confirma una acción sensible con la contraseña actual."""
    password: str = Field(..., min_length=1, max_length=128)


class SesionRenovada(BaseModel):
    """Tokens nuevos para ESTE dispositivo (los demás quedan cerrados)."""
    message: str
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
