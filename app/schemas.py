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


class PrestamoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    recurso_id: int
    usuario_id: int
    fecha_prestamo: datetime
    fecha_devolucion_esperada: datetime
    fecha_devolucion_real: Optional[datetime]
