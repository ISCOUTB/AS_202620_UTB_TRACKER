"""
Modelo SQLAlchemy del dominio de autenticación y usuarios (S8 / S9).

Representa la entidad Usuario en el sistema UTB Tracker, incluyendo
roles de acceso, trazabilidad y estado de activación.
"""
from datetime import datetime, timezone

from sqlalchemy import JSON, Boolean, Column, DateTime, Index, Integer, String, false, func
from sqlalchemy.orm import relationship

from app.core.database import Base


class Usuario(Base):
    __tablename__ = "usuarios"
    # El correo se guarda normalizado (minúsculas, sin espacios) y es único sin distinguir
    # mayúsculas también en la base: dos registros simultáneos no pueden colarse (ADR-0014).
    __table_args__ = (
        Index("uq_usuarios_email_lower", func.lower(Column("email", String)), unique=True),
    )

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True)
    fecha_registro = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    rol = Column(String, nullable=False, default="usuario_utb")
    # valores válidos: usuario_utb | administrador | auxiliar
    password = Column(String, nullable=False)
    fcm_token = Column(String, nullable=True)
    activo = Column(Boolean, nullable=False, default=True)
    # Cuenta ligada a un correo que la persona demostró poseer (ADR-0014). Las cuentas que ya
    # existían antes de la migración c3d4e5f6a7b8 quedaron verificadas.
    email_verificado = Column(Boolean, nullable=False, default=False, server_default=false())
    email_verificado_en = Column(DateTime, nullable=True)
    # Perfil personalizable (ADR-0016). Todo opcional.
    nombre_mostrar = Column(String(100), nullable=True)
    telefono = Column(String(30), nullable=True)
    dependencia = Column(String(120), nullable=True)  # dependencia o cargo
    color_avatar = Column(String(9), nullable=True)   # "#RRGGBB"
    preferencias = Column(JSON, nullable=True)        # NULL = valores por defecto
    # Sube al cambiar la contraseña o cerrar todas las sesiones (invalida tokens viejos).
    sesion_version = Column(Integer, nullable=False, default=0, server_default="0")
    updated_at = Column(
        DateTime,
        nullable=True,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    prestamos = relationship("Prestamo", backref="usuario")
