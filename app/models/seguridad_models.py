"""
Modelos de apoyo a la seguridad de las cuentas (ADR-0014).

- TokenUsado: lista de tokens de un solo uso (verificar correo, recuperar contraseña, cambiar
  correo) que ya se usaron. Se guarda el `jti` del JWT, nunca el token.
- IntentoLimitado: registro de intentos para los límites de frecuencia (login fallido, reenvío
  de correos, recuperación). Vive en la base y no en memoria: sobrevive a reinicios y funciona
  con varios procesos de la API.
"""
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String

from app.db.database import Base


def _ahora():
    return datetime.now(timezone.utc).replace(tzinfo=None)


class TokenUsado(Base):
    __tablename__ = "tokens_usados"

    jti = Column(String(64), primary_key=True)
    proposito = Column(String(40), nullable=False)
    usuario_id = Column(Integer, nullable=True, index=True)
    usado_en = Column(DateTime, nullable=False, default=_ahora)
    # Pasada esta fecha el token ya no sirve de todos modos: la fila se puede borrar.
    expira_en = Column(DateTime, nullable=False, index=True)


class IntentoLimitado(Base):
    __tablename__ = "intentos_limitados"

    id = Column(Integer, primary_key=True)
    # Ej.: "login:127.0.0.1:ana@utb.edu.co", "reenvio:12", "recuperar:ana@utb.edu.co"
    clave = Column(String(255), nullable=False, index=True)
    creado_en = Column(DateTime, nullable=False, default=_ahora, index=True)
