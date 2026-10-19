"""
Modelos SQLAlchemy del dominio de recursos y préstamos (S4 / S9 / S11).

Entidades:
- Recurso: equipos físicos del inventario.
- Prestamo: transacciones de préstamo vinculando recursos y usuarios (QS-06).
- IdempotenciaRegistro: almacenamiento de claves de idempotencia (S11 — req. 11.3)
  para evitar duplicación de préstamos ante reintentos de red del cliente móvil.
"""
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Recurso(Base):
    __tablename__ = "recursos"

    id = Column(Integer, primary_key=True, index=True)
    categoria = Column(String, nullable=False)  # video_beam, computador, aire_ac, tv, audio
    salon_id = Column(String, nullable=False)
    serial = Column(String, unique=True, nullable=False)
    estado = Column(String, nullable=False, default="disponible")
    # valores validos: disponible | prestado | dañado | mantenimiento

    prestamos = relationship("Prestamo", back_populates="recurso")


class Prestamo(Base):
    __tablename__ = "prestamos"

    id = Column(Integer, primary_key=True, index=True)
    recurso_id = Column(Integer, ForeignKey("recursos.id"), nullable=False)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    fecha_prestamo = Column(DateTime, default=datetime.utcnow)
    fecha_devolucion_esperada = Column(DateTime, nullable=False)
    fecha_devolucion_real = Column(DateTime, nullable=True)

    recurso = relationship("Recurso", back_populates="prestamos")


class IdempotenciaRegistro(Base):
    """
    Registro de idempotencia (S11 — req. 11.3).
    Garantiza que reintentos de red con la misma cabecera X-Idempotency-Key
    retornen el préstamo original sin crear duplicados.
    """
    __tablename__ = "idempotencia_registros"

    clave = Column(String, primary_key=True, index=True)
    endpoint = Column(String, nullable=False)
    prestamo_id = Column(Integer, ForeignKey("prestamos.id"), nullable=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)

    prestamo = relationship("Prestamo")
