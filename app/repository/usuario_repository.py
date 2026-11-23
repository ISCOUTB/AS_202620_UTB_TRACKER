"""Acceso a datos de usuarios (tabla `usuarios`)."""
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.middleware.permisos import Rol
from app.models.auth_models import Usuario


def por_id(db: Session, usuario_id: int) -> Usuario | None:
    return db.get(Usuario, usuario_id)


def contar_administradores_activos(db: Session) -> int:
    return db.query(func.count(Usuario.id)).filter(
        func.lower(Usuario.rol) == Rol.ADMINISTRADOR.value, Usuario.activo.is_(True)
    ).scalar() or 0
