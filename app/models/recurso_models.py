"""
Modelos SQLAlchemy del dominio de recursos y préstamos (S4 / S9 / S11).

Entidades:
- Recurso: equipos físicos del inventario.
- Prestamo: transacciones de préstamo vinculando recursos y usuarios (QS-06).
- IdempotenciaRegistro: almacenamiento de claves de idempotencia (S11 — req. 11.3)
  para evitar duplicación de préstamos ante reintentos de red del cliente móvil.
- Reporte: reportes de estado de dispositivos con imágenes.
"""
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class Recurso(Base):
    __tablename__ = "recursos"

    id = Column(Integer, primary_key=True, index=True)
    categoria = Column(String, nullable=False)  # video_beam, computador, aire_ac, tv, audio, otro
    salon_id = Column(Integer, ForeignKey("salones.id"), nullable=True, index=True)
    serial = Column(String, unique=True, nullable=False)
    estado = Column(String, nullable=False, default="disponible")
    # valores validos: disponible | prestado | dañado | mantenimiento
    descripcion = Column(String, nullable=True)
    imagen_url = Column(String, nullable=True)
    activo = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    prestamos = relationship("Prestamo", back_populates="recurso")
    reportes = relationship("Reporte", back_populates="recurso", cascade="all, delete-orphan")
    salon = relationship("Salon", back_populates="recursos")


class Prestamo(Base):
    __tablename__ = "prestamos"

    id = Column(Integer, primary_key=True, index=True)
    recurso_id = Column(Integer, ForeignKey("recursos.id"), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False, index=True)
    fecha_prestamo = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    fecha_devolucion_esperada = Column(DateTime, nullable=False)
    fecha_devolucion_real = Column(DateTime, nullable=True)
    estado = Column(String, nullable=False, default="activo")
    # valores válidos: activo | devuelto | vencido | cancelado

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
    fecha_creacion = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    prestamo = relationship("Prestamo")


class Reporte(Base):
    """
    Reportes de estado de dispositivos con imágenes.
    Permite a los usuarios reportar daños o problemas en los recursos.
    """
    __tablename__ = "reportes"

    id = Column(Integer, primary_key=True, index=True)
    recurso_id = Column(Integer, ForeignKey("recursos.id"), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False, index=True)
    estado_reportado = Column(String, nullable=False)
    descripcion = Column(Text, nullable=True)
    imagen_url = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    recurso = relationship("Recurso", back_populates="reportes")
