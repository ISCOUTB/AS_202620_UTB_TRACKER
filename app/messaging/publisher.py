"""Publicación transaccional de eventos en el outbox."""
import json
import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.messaging.models import MensajeOutbox


def publicar_evento(db: Session, tipo: str, payload: dict,
                    correlation_id: str | None = None, version: int = 1) -> MensajeOutbox:
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)
    mensaje = MensajeOutbox(
        message_id=str(uuid.uuid4()),
        tipo=tipo,
        version=version,
        payload=json.dumps(payload, default=str),
        correlation_id=correlation_id,
        estado="pendiente",
        intentos=0,
        siguiente_intento=ahora,
        creado_en=ahora,
    )
    db.add(mensaje)
    return mensaje
