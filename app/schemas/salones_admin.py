"""
Schemas Pydantic de la administración de salones (panel del auxiliar).

Cubren tres necesidades: ver en vivo quién tiene el salón, confirmar si el
profesor llegó a su clase y reportar/resolver novedades del salón.
"""
from datetime import date, datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.enums import EstadoReporteSalon, TipoReporteSalon
from app.schemas.salones import SalonResponse


class ClaseActual(BaseModel):
    horario_id: int
    materia: Optional[str] = None
    profesor: Optional[str] = None
    hora_inicio: time
    hora_fin: time


class PrestamoActual(BaseModel):
    prestamo_id: int
    usuario_id: int
    usuario_nombre: str
    estado: str
    fecha_inicio: datetime
    fecha_fin: datetime
    motivo: Optional[str] = None


class OcupacionSalon(BaseModel):
    """Foto en vivo de un salón: quién lo tiene y en qué situación está."""

    salon: SalonResponse
    ocupante: str = Field(description="libre | clase | prestamo")
    clase_actual: Optional[ClaseActual] = None
    prestamo_actual: Optional[PrestamoActual] = None
    profesor_presente: Optional[bool] = Field(
        default=None,
        description="None = sin confirmar todavía; solo aplica cuando hay clase_actual",
    )
    solicitudes_pendientes: int = 0
    reportes_abiertos: int = 0


class PresenciaUpdate(BaseModel):
    profesor_presente: bool
    nota: Optional[str] = Field(default=None, max_length=300)


class PresenciaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    salon_id: int
    horario_id: int
    fecha: date
    profesor_presente: bool
    nota: Optional[str] = None
    registrado_por: int


class ReporteSalonCreate(BaseModel):
    tipo: TipoReporteSalon
    descripcion: str = Field(..., min_length=3, max_length=1000)


class ReporteSalonUpdate(BaseModel):
    estado: EstadoReporteSalon


class ReporteSalonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    salon_id: int
    usuario_id: int
    tipo: str
    descripcion: str
    estado: str
    created_at: Optional[datetime] = None
    resuelto_en: Optional[datetime] = None
