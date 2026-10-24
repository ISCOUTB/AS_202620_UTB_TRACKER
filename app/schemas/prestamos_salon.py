"""
Schemas Pydantic para el módulo de préstamos de salón.

Define los contratos de entrada/salida para solicitudes de préstamo
de salones en franjas horarias disponibles.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


class PrestamoSalonCreate(BaseModel):
    salon_id: int
    fecha_inicio: datetime
    fecha_fin: datetime
    motivo: Optional[str] = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def validar_fechas(self):
        if self.fecha_fin <= self.fecha_inicio:
            raise ValueError("fecha_fin debe ser posterior a fecha_inicio")
        return self


class PrestamoSalonUpdate(BaseModel):
    estado: str = Field(..., description="pendiente | aprobado | rechazado | en_uso | finalizado | cancelado")


class PrestamoSalonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    salon_id: int
    usuario_id: int
    fecha_inicio: datetime
    fecha_fin: datetime
    motivo: Optional[str] = None
    estado: str
    created_at: Optional[datetime] = None
