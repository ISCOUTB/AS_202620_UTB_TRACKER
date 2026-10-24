"""
Schemas Pydantic para el módulo de salones.

Define los contratos de entrada/salida de la API para CRUD de salones,
consulta de disponibilidad y franjas horarias libres.
"""
from datetime import datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SalonCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=50, examples=["A-301"])
    ubicacion: str = Field(..., min_length=1, examples=["Edificio A, Piso 3"])
    edificio: Optional[str] = None
    piso: Optional[int] = None
    capacidad: int = Field(..., gt=0, examples=[40])
    estado: str = Field(default="disponible")


class SalonUpdate(BaseModel):
    nombre: Optional[str] = Field(default=None, min_length=1, max_length=50)
    ubicacion: Optional[str] = Field(default=None, min_length=1)
    edificio: Optional[str] = None
    piso: Optional[int] = None
    capacidad: Optional[int] = Field(default=None, gt=0)
    estado: Optional[str] = None


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
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class FranjaDisponible(BaseModel):
    dia_semana: int
    hora_inicio: time
    hora_fin: time


class SalonConDisponibilidad(SalonResponse):
    franjas_disponibles: list[FranjaDisponible] = []
