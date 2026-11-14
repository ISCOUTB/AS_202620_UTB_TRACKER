"""Schemas de la bitácora de auditoría (solo lectura)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class AuditoriaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    ocurrio_en: datetime
    actor_id: Optional[int] = None
    actor_nombre: Optional[str] = None
    accion: str
    entidad: str
    entidad_id: Optional[int] = None
    detalle: Optional[str] = None
    request_id: Optional[str] = None
