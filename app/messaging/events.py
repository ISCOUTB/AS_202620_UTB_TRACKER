"""
Contrato de eventos de dominio — mensajería asíncrona (taller).

Define la estructura canónica de los mensajes que viajan por el outbox.
Versión 1 del evento "prestamo.creado".

Reglas de compatibilidad:
  - El consumidor ignora campos DESCONOCIDOS (uso de model_config con extra="ignore").
  - Si la versión recibida NO es 1, el worker marca el mensaje como "muerto"
    con un error explícito (no descarte silencioso).
  - El payload lleva usuario_id (no el email): el consumidor resuelve el email
    consultando la base de datos al momento de procesar.
"""
from datetime import datetime
from typing import Any, Dict
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PayloadPrestamoCreado(BaseModel):
    """Datos de negocio del evento 'prestamo.creado'."""
    model_config = ConfigDict(extra="ignore")

    prestamo_id: int
    usuario_id: int
    recurso_id: int
    fecha_devolucion_esperada: datetime


class EventoPrestamoCreado(BaseModel):
    """
    Sobre del evento de dominio 'prestamo.creado', versión 1.

    Campos de sobre (envelope):
      - message_id:     UUID único del mensaje (para deduplicación).
      - tipo:           Tipo de evento en notación de punto.
      - version:        Versión del contrato (int). Si no es 1, el worker
                        rechaza con error explícito en lugar de ignorar.
      - correlation_id: request_id de la petición HTTP que originó el evento.
      - ocurrido_en:    Instante UTC en que ocurrió el hecho de dominio.
      - payload:        Datos de negocio tipados.
    """
    model_config = ConfigDict(extra="ignore")

    message_id: UUID
    tipo: str = "prestamo.creado"
    version: int = 1
    correlation_id: str
    ocurrido_en: datetime
    payload: PayloadPrestamoCreado


# Versiones soportadas por el consumidor actual
VERSIONES_SOPORTADAS: frozenset[int] = frozenset({1})
