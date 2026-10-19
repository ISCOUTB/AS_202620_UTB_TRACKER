"""
Schemas Pydantic: definen la forma exacta de entrada/salida de la API.
Este es "el contrato" HTTP/JSON entre el backend y el cliente Flutter
(ver Restricciones tecnicas, arc42 seccion 2).
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class RecursoCreate(BaseModel):
    categoria: str
    salon_id: str
    serial: str


class RecursoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    categoria: str
    salon_id: str
    serial: str
    estado: str


class PrestamoCreate(BaseModel):
    recurso_id: int
    usuario_id: int
    fecha_devolucion_esperada: datetime


def _ensure_prestamo_contract(schema: dict) -> None:
    req = schema.setdefault("required", [])
    if "fecha_devolucion_real" not in req:
        req.append("fecha_devolucion_real")


class PrestamoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True, json_schema_extra=_ensure_prestamo_contract)

    id: int
    recurso_id: int
    usuario_id: int
    fecha_prestamo: datetime
    fecha_devolucion_esperada: datetime
    fecha_devolucion_real: Optional[datetime] = None
