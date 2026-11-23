"""
Schemas Pydantic para el módulo de préstamos de salón.

Define los contratos de entrada/salida para solicitudes de préstamo
de salones en franjas horarias disponibles.
"""
from datetime import datetime, timedelta
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

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
    # Opcional para no romper a la app anterior; la app nueva la exige al rechazar.
    respuesta: Optional[str] = Field(default=None, max_length=500)


class RespuestaSolicitud(BaseModel):
    """POST /prestamos-salon/{id}/aprobar|rechazar (ADR-0018)."""
    respuesta: Optional[str] = Field(default=None, max_length=500)

    @field_validator("respuesta")
    @classmethod
    def _limpiar(cls, v: Optional[str]) -> Optional[str]:
        v = (v or "").strip()
        return v or None


class RechazoSolicitud(BaseModel):
    """Rechazar exige explicar por qué: el estudiante ve el motivo."""
    respuesta: str = Field(..., min_length=3, max_length=500,
                           description="Motivo del rechazo que verá el estudiante")

    @field_validator("respuesta")
    @classmethod
    def _no_vacio(cls, v: str) -> str:
        if len(v.strip()) < 3:
            raise ValueError("Escribe el motivo del rechazo (al menos 3 caracteres)")
        return v.strip()


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
    salon_nombre: Optional[str] = None
    usuario_nombre: Optional[str] = None
    # ADR-0018 (campos nuevos con valor por defecto: la app anterior los ignora)
    respuesta: Optional[str] = None
    atendido_por_nombre: Optional[str] = None
    atendido_en: Optional[datetime] = None
    conflicto: Optional[str] = Field(
        default=None, description="Solo en la bandeja: con qué choca la franja, si choca")
    # ADR-0022: el salón de una solicitud pendiente o aprobada quedó deshabilitado.
    aviso_salon: Optional[str] = Field(
        default=None, description="Motivo si el salón de esta solicitud está deshabilitado")
