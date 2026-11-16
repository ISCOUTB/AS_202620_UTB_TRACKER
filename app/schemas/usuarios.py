"""Esquemas de la gestión de usuarios por el administrador (ADR-0018)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.core import permisos


class UsuarioAdmin(BaseModel):
    """Fila de la lista de usuarios (pantalla Usuarios del administrador)."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    nombre_mostrar: Optional[str] = None
    email: str
    rol: str
    rol_etiqueta: str
    activo: bool
    email_verificado: bool
    dependencia: Optional[str] = None
    fecha_registro: Optional[datetime] = None
    ultima_actividad: Optional[datetime] = Field(
        default=None, description="Último registro de la bitácora donde la persona actuó")

    @classmethod
    def de(cls, user, ultima_actividad=None) -> "UsuarioAdmin":
        return cls(
            id=user.id, nombre=user.nombre, nombre_mostrar=user.nombre_mostrar,
            email=user.email, rol=user.rol, rol_etiqueta=permisos.etiqueta(user.rol),
            activo=bool(user.activo), email_verificado=bool(user.email_verificado),
            dependencia=user.dependencia, fecha_registro=user.fecha_registro,
            ultima_actividad=ultima_actividad,
        )


class CambioRol(BaseModel):
    rol: str = Field(..., description="usuario_utb (Estudiante), auxiliar (Auditor), "
                                      "administrador (Administrador)")


class CambioEstado(BaseModel):
    activo: bool
