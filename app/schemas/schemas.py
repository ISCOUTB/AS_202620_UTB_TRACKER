"""
Schemas Pydantic: definen la forma exacta de entrada/salida de la API.
Este es "el contrato" HTTP/JSON entre el backend y el cliente Flutter
(ver Restricciones tecnicas, arc42 seccion 2).

Mejoras aplicadas:
- Enums para categoria y estado.
- Schema de devolución de préstamo.
- Schema de reporte con imagen.
- Schema de actualización de recurso.
- Schema de paginación reutilizable.
"""
from datetime import datetime
from typing import Generic, Optional, TypeVar

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.enums import CategoriaRecurso, EstadoPrestamo, EstadoRecurso

T = TypeVar("T")


# ─── Recursos ────────────────────────────────────────────────────────────────

class RecursoCreate(BaseModel):
    categoria: CategoriaRecurso
    salon_id: Optional[int] = None
    serial: str = Field(..., min_length=1, max_length=100)
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = None


class RecursoUpdate(BaseModel):
    categoria: Optional[CategoriaRecurso] = None
    salon_id: Optional[int] = None
    serial: Optional[str] = Field(default=None, min_length=1, max_length=100)
    estado: Optional[EstadoRecurso] = None
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = None


class RecursoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    categoria: str
    salon_id: Optional[int] = None
    serial: str
    estado: str
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = None
    activo: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


# ─── Préstamos de recurso ────────────────────────────────────────────────────

class PrestamoCreate(BaseModel):
    recurso_id: int
    usuario_id: int
    fecha_devolucion_esperada: datetime


def _ensure_prestamo_contract(schema: dict) -> None:
    req = schema.setdefault("required", [])
    if "fecha_devolucion_real" not in req:
        req.append("fecha_devolucion_real")


class PrestamoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True, json_schema_extra=_ensure_prestamo_contract)

    id: int
    recurso_id: int
    usuario_id: int
    fecha_prestamo: datetime
    fecha_devolucion_esperada: datetime
    fecha_devolucion_real: Optional[datetime] = None
    estado: str = "activo"


class PrestamoDevolver(BaseModel):
    """Schema para la devolución de un préstamo."""
    notas: Optional[str] = Field(default=None, max_length=500)


# ─── Reportes de recurso ─────────────────────────────────────────────────────

class ReporteCreate(BaseModel):
    estado_reportado: EstadoRecurso
    descripcion: Optional[str] = Field(default=None, max_length=1000)
    imagen_url: Optional[str] = None


class ReporteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    recurso_id: int
    usuario_id: int
    estado_reportado: str
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = None
    created_at: Optional[datetime] = None


# ─── Paginación ──────────────────────────────────────────────────────────────

class PaginatedResponse(BaseModel, Generic[T]):
    """Respuesta paginada reutilizable para cualquier tipo de listado."""
    items: list[T]
    total: int
    page: int
    page_size: int
    pages: int
