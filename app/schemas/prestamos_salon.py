"""
Schemas Pydantic para el módulo de préstamos de salón.

Define los contratos de entrada/salida para solicitudes de préstamo
de salones en franjas horarias disponibles.
"""
from datetime import datetime, timedelta
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

# Límites de duración configurables
DURACION_MINIMA = timedelta(minutes=30)
DURACION_MAXIMA = timedelta(hours=4)


class PrestamoSalonCreate(BaseModel):
    salon_id: int
    fecha_inicio: datetime
    fecha_fin: datetime
    motivo: Optional[str] = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def validar_fechas(self):
        if self.fecha_fin <= self.fecha_inicio:
            raise ValueError("fecha_fin debe ser posterior a fecha_inicio")
        duracion = self.fecha_fin - self.fecha_inicio
        if duracion < DURACION_MINIMA:
            raise ValueError(
                f"El préstamo debe tener al menos {int(DURACION_MINIMA.total_seconds() // 60)} minutos de duración"
            )
        if duracion > DURACION_MAXIMA:
            raise ValueError(
                f"El préstamo no puede exceder {int(DURACION_MAXIMA.total_seconds() // 3600)} horas"
            )
        return self


# Estados válidos de un préstamo de salón
EstadoPrestamo = Literal["pendiente", "aprobado", "rechazado", "en_uso", "finalizado", "cancelado"]


class PrestamoSalonUpdate(BaseModel):
    estado: EstadoPrestamo = Field(..., description="Estado destino del préstamo")


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
