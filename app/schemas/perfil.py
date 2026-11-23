"""
Schemas del perfil propio y de las preferencias guardadas en el servidor (ADR-0016).

Las preferencias tienen valores por defecto: una cuenta sin preferencias guardadas (NULL) se
comporta igual que una con todo encendido y texto normal.
"""
import re
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.middleware import permisos as permisos_core
from app.service.politica import PASSWORD_MINIMO, es_institucional, normalizar_nombre

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


class RolCatalogo(BaseModel):
    """Un rol con sus permisos, tal como están en app/middleware/matriz_permisos.json (ADR-0025)."""
    valor: str = Field(description="Valor guardado del rol")
    etiqueta: str
    descripcion: str
    permisos: list[str]


class PerfilResponse(BaseModel):
    """GET /auth/me: perfil completo. Los campos nuevos tienen valor por defecto (contrato)."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    rol: str
    fecha_registro: Optional[datetime] = None
    nombre_mostrar: Optional[str] = None
    telefono: Optional[str] = None
    dependencia: Optional[str] = None
    color_avatar: Optional[str] = None
    preferencias: Preferencias = Field(default_factory=Preferencias)
    # ADR-0018: `rol` conserva el valor guardado (usuario_utb | auxiliar | administrador) para
    # las APK instaladas; la etiqueta y los permisos se calculan de app/middleware/permisos.py.
    rol_etiqueta: str = ""
    permisos: list[str] = Field(default_factory=list)
    # ADR-0019: False en cuentas antiguas con correo no institucional (la app muestra un aviso
    # para pasarse al de la UTB). Nunca bloquea la entrada.
    correo_institucional: bool = True
    # ADR-0019: el rol es de solo lectura; de dónde viene y el cargo de la asignación.
    rol_origen: Literal["base", "correo", "manual"] = "base"
    rol_origen_texto: str = ""
    cargo: Optional[str] = None
    # ADR-0020: la app pide GET /auth/me/foto?v=<foto_version> y la guarda en caché por versión.
    tiene_foto: bool = False
    foto_version: int = 0

    @model_validator(mode="after")
    def _permisos_del_rol(self):
        self.rol_etiqueta = permisos_core.etiqueta(self.rol)
        self.permisos = permisos_core.lista_permisos(self.rol)
        self.correo_institucional = es_institucional(self.email)
        return self

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


class FotoEstado(BaseModel):
    """Respuesta de PUT/DELETE /auth/me/foto."""
    tiene_foto: bool
    foto_version: int = 0
    tipo: Optional[str] = None
    tamano: Optional[int] = None
    ancho: Optional[int] = None
    alto: Optional[int] = None
