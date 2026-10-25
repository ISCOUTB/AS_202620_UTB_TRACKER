"""
Modelos SQLAlchemy del módulo de mensajería asíncrona (taller).

Tablas:
  - mensajes_outbox:          Cola persistente de mensajes a entregar (patrón Outbox).
  - notificaciones_procesadas: Registro de deduplicación de mensajes ya procesados.

La combinación de ambas tablas garantiza entrega at-least-once con
deduplicación en el consumidor:
  1. El productor inserta en mensajes_outbox EN LA MISMA TRANSACCIÓN que
     el hecho de negocio (creación de préstamo).
  2. El worker lee mensajes pendientes, verifica notificaciones_procesadas,
     entrega y luego marca como "enviado".
  3. La deduplicación en consumidor evita procesar mensajes que ya fueron
     confirmados en la BD. Si el worker muere entre la entrega externa
     y el commit local, el correo puede duplicarse (semántica at-least-once).
"""
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String, Text

from app.core.database import Base


class MensajeOutbox(Base):
    """
    Cola persistente de mensajes de dominio (patrón Outbox).

    Estados posibles:
      - "pendiente": recién insertado, esperando procesamiento.
      - "enviado":   procesado exitosamente.
      - "muerto":    agotados los intentos máximos; requiere intervención manual.
    """
    __tablename__ = "mensajes_outbox"

    id = Column(Integer, primary_key=True, index=True)
    # UUID del mensaje — único por fila; permite idempotencia en el consumidor
    message_id = Column(String, unique=True, nullable=False, index=True)
    # Tipo de evento, ej. "prestamo.creado"
    tipo = Column(String, nullable=False)
    # Versión del contrato (entero); permite evolución sin romper consumidores
    version = Column(Integer, nullable=False, default=1)
    # Cuerpo del mensaje serializado como JSON
    payload = Column(Text, nullable=False)
    # request_id de la petición HTTP que generó el evento
    correlation_id = Column(String, nullable=True)
    # Estado actual del mensaje
    estado = Column(String, nullable=False, default="pendiente")
    # Número de intentos de entrega realizados
    intentos = Column(Integer, nullable=False, default=0)
    # Próximo instante en que el worker debe intentar el procesamiento
    siguiente_intento = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    # Descripción del último error, para diagnóstico (nullable = sin error aún)
    ultimo_error = Column(Text, nullable=True)
    # Marca de creación
    creado_en = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    # Marca de procesamiento exitoso
    procesado_en = Column(DateTime, nullable=True)


class NotificacionProcesada(Base):
    """
    Registro de deduplicación del consumidor.

    Cada vez que el worker entrega con éxito un mensaje, inserta su
    message_id aquí. Si el worker vuelve a ver el mismo message_id
    (por reprocesamiento tras fallo), sabe que ya fue enviado y omite
    la entrega sin marcar error.
    """
    __tablename__ = "notificaciones_procesadas"

    # message_id actúa como PK — garantiza unicidad a nivel de BD
    message_id = Column(String, primary_key=True, index=True)
    procesado_en = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
