"""
Schemas de la habilitación de salones (manual) y su historial (ADR-0022).
"""
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.prestamos_salon import PrestamoSalonResponse
from app.schemas.salones import SalonResponse
from app.services.estado_salon import MotivoDeshabilitacion


class HabilitacionUpdate(BaseModel):
    """Deshabilitar exige `motivo` (y nota si es 'otro'); habilitar borra motivo, nota y fecha."""
    habilitado: bool
    motivo: Optional[MotivoDeshabilitacion] = None
    nota: Optional[str] = Field(default=None, max_length=300)
    reapertura_estimada: Optional[date] = None


class HabilitacionResultado(BaseModel):
    salon: SalonResponse
    # Solicitudes pendientes o aprobadas que todavía no terminan: el Auditor decide qué hacer
    # (no se cancelan solas) y a cada estudiante le llega un aviso.
    solicitudes_afectadas: list[PrestamoSalonResponse] = []


class HabilitacionLote(HabilitacionUpdate):
    """Todos los salones activos de un edificio (y de un piso, si se indica)."""
    edificio: str = Field(..., min_length=1, max_length=20, examples=["A1"])
    piso: Optional[int] = Field(default=None, ge=0, le=99)


class VistaPreviaLote(BaseModel):
    salones: list[str]
    sin_cambio: list[str]
    solicitudes_afectadas: int


class HistorialSalonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    accion: str
    descripcion: str
    actor_nombre: Optional[str] = None
    creado_en: datetime


class ResumenPiso(BaseModel):
    edificio: str
    piso: Optional[int] = None
    total: int
    libres: int
    ocupados: int
    deshabilitados: int
