"""
Schemas Pydantic para el módulo de salones.

Define los contratos de entrada/salida de la API para CRUD de salones,
consulta de disponibilidad y franjas horarias libres.
"""
from datetime import datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.enums import EstadoSalon, TipoSalon


def _recortar_descripcion(v):
    """Quita espacios sobrantes; vacío = sin descripción. El máximo (500) se valida después."""
    if v is None:
        return None
    v = " ".join(str(v).split())
    return v or None


class SalonCreate(BaseModel):
    # Código del catálogo UTB (ADR-0021): A1-101 = edificio A1, piso 1, salón 01. Si el nombre
    # tiene esa forma, edificio/piso deben coincidir y la ubicación se escribe sola
    # ("Edificio A1, piso 1"), sea cual sea el texto enviado.
    nombre: str = Field(..., min_length=1, max_length=50, examples=["A1-101"])
    ubicacion: str = Field(..., min_length=1, examples=["Edificio A1, piso 1"])
    edificio: Optional[str] = None
    piso: Optional[int] = None
    capacidad: int = Field(..., gt=0, examples=[40])
    # Usa el Enum centralizado para rechazar valores inválidos con 422
    estado: EstadoSalon = Field(default=EstadoSalon.DISPONIBLE)
    tipo: TipoSalon = Field(default=TipoSalon.AULA)
    descripcion: Optional[str] = Field(default=None, max_length=500)

    _desc = field_validator("descripcion", mode="before")(_recortar_descripcion)


class SalonUpdate(BaseModel):
    nombre: Optional[str] = Field(default=None, min_length=1, max_length=50)
    ubicacion: Optional[str] = Field(default=None, min_length=1)
    edificio: Optional[str] = None
    piso: Optional[int] = None
    capacidad: Optional[int] = Field(default=None, gt=0)
    # Usa el Enum centralizado para rechazar valores inválidos con 422
    estado: Optional[EstadoSalon] = None
    tipo: Optional[TipoSalon] = None
    descripcion: Optional[str] = Field(default=None, max_length=500)

    _desc = field_validator("descripcion", mode="before")(_recortar_descripcion)


class EquipoCategoria(BaseModel):
    """Equipamiento calculado (ADR-0017): no se guarda, sale de los recursos activos."""
    categoria: str
    total: int
    operativos: int


class SalonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    ubicacion: str
    edificio: Optional[str] = None
    piso: Optional[int] = None
    capacidad: int
    estado: str
    activo: bool = True
    # True = capacidad por defecto sin dato oficial (ADR-0021): la app la marca "estimada".
    capacidad_estimada: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    # Campos nuevos con valor por defecto: no rompen el contrato (ADR-0017).
    tipo: str = "aula"
    descripcion: Optional[str] = None
    equipamiento: list[EquipoCategoria] = []
    tipo_sugerido: Optional[str] = None


class FranjaDisponible(BaseModel):
    dia_semana: int
    hora_inicio: time
    hora_fin: time


class SalonConDisponibilidad(SalonResponse):
    franjas_disponibles: list[FranjaDisponible] = []
