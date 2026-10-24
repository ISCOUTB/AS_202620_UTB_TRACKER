"""
Modelo SQLAlchemy del dominio de autenticación y usuarios (S8 / S9).

Representa la entidad Usuario en el sistema UTB Tracker, incluyendo
roles de acceso, trazabilidad y estado de activación.
"""
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True)
    fecha_registro = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    rol = Column(String, nullable=False, default="usuario_utb")
    # valores válidos: usuario_utb | administrador | auxiliar
    password = Column(String, nullable=False)
    activo = Column(Boolean, nullable=False, default=True)
    updated_at = Column(
        DateTime,
        nullable=True,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    prestamos = relationship("Prestamo", backref="usuario")