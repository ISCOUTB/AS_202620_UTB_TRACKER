"""
Schemas del catálogo de salones UTB (ADR-0021): crear varios por rango y reporte de salones
que no siguen la regla del código.
"""
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.enums import TipoSalon


class RangoCatalogo(BaseModel):
    """A{edificio}-{piso}{desde..hasta}. Ej.: edificio 2, piso 5, 1..5 -> A2-501 … A2-505."""
    edificio: int = Field(..., ge=1, le=9, examples=[2])
    piso: int = Field(..., ge=1, le=9, examples=[5])
    desde: int = Field(..., ge=1, le=99, examples=[1])
    hasta: int = Field(..., ge=1, le=99, examples=[5])
    # Sin capacidad = 40 marcada como estimada (no hay dato oficial).
    capacidad: Optional[int] = Field(default=None, gt=0, le=1000)
    tipo: TipoSalon = TipoSalon.AULA


class VistaPreviaRango(BaseModel):
    edificio: str
    piso: int
    ubicacion: str
    nuevos: list[str]
    existentes: list[str]


class ResultadoRango(VistaPreviaRango):
    creados: list[str]


class SalonFueraCatalogo(BaseModel):
    id: int
    nombre: str
    edificio: Optional[str] = None
    piso: Optional[int] = None
    tiene_historial: bool
    problema: str
    propuesta: str

