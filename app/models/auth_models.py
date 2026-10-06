from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True)
    fecha_registro = Column(DateTime, nullable=False, default=datetime.utcnow)
    rol = Column(String, nullable=False, default="Usuario")  # "administrador" o "usuario_utb"
    password = Column(String, nullable=False)