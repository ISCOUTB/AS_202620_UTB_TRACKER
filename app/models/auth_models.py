"""
Modelo SQLAlchemy del dominio de autenticación y usuarios (S8 / S9).

Representa la entidad Usuario en el sistema UTB Tracker, incluyendo
roles de acceso, trazabilidad y estado de activación.
"""
from datetime import datetime, timezone

from sqlalchemy import (
    JSON, BigInteger, Boolean, Column, DateTime, ForeignKey, Index, Integer, LargeBinary,
    String, false, func,
)
from sqlalchemy.orm import relationship

from app.db.database import Base


def _rol_alto(contexto) -> bool:
    return (contexto.get_current_parameters().get("rol") or "usuario_utb") != "usuario_utb"


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
    # ADR-0019: True = el rol lo puso un administrador (o la consola) y la asignación automática
    # por correo NO lo pisa. Un rol alto creado directamente (scripts, seed, pruebas) nace
    # manual; la migración marcó así a todas las cuentas que ya tenían un rol alto.
    rol_manual = Column(Boolean, nullable=False, default=_rol_alto, server_default=false())
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


class AsignacionRol(Base):
    """Lista que mantiene el administrador: correo institucional EXACTO -> rol (ADR-0019).

    Sin comodines ni patrones: un rol alto solo se le da a un correo escrito completo, y solo
    se aplica cuando la persona demostró que el correo es suyo (lo verificó).
    """
    __tablename__ = "asignaciones_rol"

    id = Column(Integer, primary_key=True)
    correo = Column(String(254), nullable=False, unique=True)  # normalizado (minúsculas)
    rol = Column(String(20), nullable=False)
    cargo = Column(String(120), nullable=True)                 # p. ej. "Auxiliar de planta"
    creado_por_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    creado_en = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    actualizado_en = Column(DateTime, nullable=True, onupdate=lambda: datetime.now(timezone.utc))


class FotoPerfil(Base):
    """Foto de perfil ya reducida (ADR-0020). Tabla aparte para no cargar bytes en cada consulta
    de `usuarios`; funciona igual en SQLite, PostgreSQL y Docker sin volúmenes nuevos.
    Se borra al quitar la foto o al desactivar la cuenta."""
    __tablename__ = "fotos_perfil"

    usuario_id = Column(Integer, ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True)
    contenido = Column(LargeBinary, nullable=False)  # sin metadatos (EXIF/GPS quitados)
    tipo = Column(String(20), nullable=False)        # image/jpeg | image/png (por su firma)
    tamano = Column(Integer, nullable=False)         # bytes
    ancho = Column(Integer, nullable=False)
    alto = Column(Integer, nullable=False)
    # Milisegundos desde 1970 de la última subida: la app la usa como clave de caché.
    version = Column(BigInteger, nullable=False)
    actualizado_en = Column(DateTime, nullable=False)
