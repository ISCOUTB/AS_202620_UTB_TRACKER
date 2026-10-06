"""
Modelos SQLAlchemy del corte vertical: Recurso y Prestamo.

Usuario y Salon quedan como referencias minimas (solo lo necesario
para las llaves foraneas de este corte) - su modelo completo se
desarrolla cuando se implemente el modulo de usuarios.
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
