"""
Modelos SQLAlchemy del dominio de salones, horarios y préstamos de salón.

Entidades:
- Salon: aulas y laboratorios de la universidad.
- Horario: franjas horarias asignadas a profesores/materias por semestre.
- PrestamoSalon: solicitudes de préstamo de salón en horarios libres.
"""
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Time,
)
from sqlalchemy.orm import relationship

from app.core.database import Base


class Salon(Base):
    __tablename__ = "salones"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)       # e.g. "A-301"
    ubicacion = Column(String, nullable=False)                  # e.g. "Edificio A, Piso 3"
    edificio = Column(String, nullable=True)
    piso = Column(Integer, nullable=True)
    capacidad = Column(Integer, nullable=False)
    estado = Column(String, nullable=False, default="disponible")
    # valores válidos: disponible | ocupado | mantenimiento | fuera_servicio
    activo = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relaciones
    horarios = relationship("Horario", back_populates="salon", cascade="all, delete-orphan")
    prestamos_salon = relationship("PrestamoSalon", back_populates="salon")
    recursos = relationship("Recurso", back_populates="salon")


class Horario(Base):
    __tablename__ = "horarios"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey("salones.id"), nullable=False, index=True)
    dia_semana = Column(Integer, nullable=False)  # 1=Lunes … 7=Domingo
    hora_inicio = Column(Time, nullable=False)
    hora_fin = Column(Time, nullable=False)
    profesor = Column(String, nullable=True)
    materia = Column(String, nullable=True)
    semestre = Column(String, nullable=True)       # e.g. "2026-2"
    activo = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    salon = relationship("Salon", back_populates="horarios")


class PrestamoSalon(Base):
    __tablename__ = "prestamos_salon"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey("salones.id"), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False, index=True)
    fecha_inicio = Column(DateTime, nullable=False)
    fecha_fin = Column(DateTime, nullable=False)
    motivo = Column(String, nullable=True)
    estado = Column(String, nullable=False, default="pendiente")
    # valores válidos: pendiente | aprobado | rechazado | en_uso | finalizado | cancelado
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    salon = relationship("Salon", back_populates="prestamos_salon")
