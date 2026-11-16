"""
Schemas del estado de los equipos fijos de un salón y de las plantillas (ADR-0022).
"""
from typing import Optional

from pydantic import BaseModel, Field, field_validator

from app.schemas.salones_admin import ReporteSalonResponse
from app.schemas.schemas import RecursoOut


class EstadoEquipoUpdate(BaseModel):
    """operativo (se guarda "disponible") | dañado | mantenimiento. "prestado" no es válido."""
    estado: str = Field(..., examples=["dañado"])
    nota: Optional[str] = Field(default=None, max_length=300)
    # Vincular un reporte de tipo "equipo" ya abierto en el mismo salón (opcional).
    reporte_salon_id: Optional[int] = None

    @field_validator("estado", mode="before")
    @classmethod
    def _normalizar(cls, v):
        v = str(v or "").strip().lower()
        return {"operativo": "disponible", "danado": "dañado", "en_mantenimiento": "mantenimiento"}.get(v, v)


class EstadoEquipoResultado(BaseModel):
    recurso: RecursoOut
    sugerir_reporte: bool = False
    reportes_equipo_abiertos: list[ReporteSalonResponse] = []


class Plantilla(BaseModel):
    id: str
    nombre: str
    descripcion: str
    equipos: dict[str, int]


class AplicarPlantilla(BaseModel):
    plantilla: str = Field(..., examples=["aula_estandar"])
    salon_ids: list[int] = Field(..., min_length=1, max_length=100)
    computadores: Optional[int] = Field(default=None, ge=1, le=60)


class PlantillaPorSalon(BaseModel):
    salon_id: int
    salon_nombre: str
    agregar: dict[str, int]
