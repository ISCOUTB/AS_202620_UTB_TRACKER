"""
Schemas Pydantic para el módulo de horarios.

Define los contratos de entrada/salida para gestión de horarios académicos,
incluyendo carga masiva de horarios por semestre.
"""
from datetime import datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


class HorarioCreate(BaseModel):
    salon_id: int
    dia_semana: int = Field(..., ge=1, le=7, description="1=Lunes, 7=Domingo")
    hora_inicio: time
    hora_fin: time
    profesor: Optional[str] = None
    materia: Optional[str] = None
    semestre: Optional[str] = Field(default=None, examples=["2026-2"])

    @model_validator(mode="after")
    def validar_horas(self):
        if self.hora_fin <= self.hora_inicio:
            raise ValueError("hora_fin debe ser posterior a hora_inicio")
        return self


class HorarioUpdate(BaseModel):
    dia_semana: Optional[int] = Field(default=None, ge=1, le=7)
    hora_inicio: Optional[time] = None
    hora_fin: Optional[time] = None
    profesor: Optional[str] = None
    materia: Optional[str] = None
    semestre: Optional[str] = None
    activo: Optional[bool] = None


class HorarioResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    salon_id: int
    dia_semana: int
    hora_inicio: time
    hora_fin: time
    profesor: Optional[str] = None
    materia: Optional[str] = None
    semestre: Optional[str] = None
    activo: bool = True
    created_at: Optional[datetime] = None


class HorarioBulkCreate(BaseModel):
    """Permite cargar múltiples horarios de un semestre en una sola petición."""
    items: list[HorarioCreate] = Field(..., min_length=1)
