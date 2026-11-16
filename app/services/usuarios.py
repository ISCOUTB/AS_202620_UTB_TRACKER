"""
Gestión de usuarios y roles por el administrador (ADR-0018).

Reglas de seguridad:
- Solo un administrador llega aquí (permiso `usuarios.gestionar`, en el router).
- Nadie se cambia el rol ni se desactiva a sí mismo desde el panel (409).
- Nunca queda el sistema sin un administrador ACTIVO (409).
- Cambiar el rol o desactivar sube `sesion_version`: los tokens abiertos de esa persona dejan
  de valer y el cambio aplica de inmediato (ADR-0014).
- Todo cambio queda en la bitácora de auditoría con quién lo hizo y a quién (ADR-0010).
"""
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core import permisos
from app.core.permisos import Rol
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario
from app.services import auditoria

MSG_NO_ENCONTRADO = "Usuario no encontrado"
MSG_A_SI_MISMO = "No puedes cambiar tu propio rol ni desactivarte desde el panel."
MSG_ULTIMO_ADMIN = (
    "Es el último administrador activo: asigna primero el rol de administrador a otra persona."
)


def _obtener(db: Session, usuario_id: int) -> Usuario:
    user = db.get(Usuario, usuario_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_NO_ENCONTRADO)
    return user


def _es_admin_activo(user: Usuario) -> bool:
    return permisos.normalizar_rol(user.rol) == Rol.ADMINISTRADOR.value and bool(user.activo)


def administradores_activos(db: Session) -> int:
    return db.query(func.count(Usuario.id)).filter(
        func.lower(Usuario.rol) == Rol.ADMINISTRADOR.value, Usuario.activo.is_(True)
    ).scalar() or 0


def proteger_ultimo_admin(db: Session, user: Usuario) -> None:
    """409 si `user` es el único administrador activo (antes de degradarlo o desactivarlo)."""
    if _es_admin_activo(user) and administradores_activos(db) <= 1:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_ULTIMO_ADMIN)


def _invalidar_sesiones(user: Usuario) -> None:
    user.sesion_version = (user.sesion_version or 0) + 1


def listar(
    db: Session, busqueda: Optional[str] = None, rol: Optional[str] = None,
    activo: Optional[bool] = None, skip: int = 0, limit: int = 50,
) -> tuple[list[tuple[Usuario, object]], int]:
    """Usuarios con su última actividad (último registro en la bitácora donde actuaron).

    La última actividad sale de UNA subconsulta agrupada, no de una consulta por usuario.
    """
    ultima = (
        db.query(RegistroAuditoria.actor_id.label("uid"),
                 func.max(RegistroAuditoria.ocurrio_en).label("en"))
        .filter(RegistroAuditoria.actor_id.isnot(None))
        .group_by(RegistroAuditoria.actor_id)
        .subquery()
    )
    query = db.query(Usuario, ultima.c.en).outerjoin(ultima, ultima.c.uid == Usuario.id)
    if busqueda and busqueda.strip():
        termino = f"%{busqueda.strip()}%"
        query = query.filter(or_(Usuario.nombre.ilike(termino), Usuario.email.ilike(termino),
                                 Usuario.nombre_mostrar.ilike(termino)))
    if rol:
        query = query.filter(func.lower(Usuario.rol) == permisos.normalizar_rol(rol))
    if activo is not None:
        query = query.filter(Usuario.activo.is_(activo))
    total = query.order_by(None).count()
    filas = query.order_by(Usuario.nombre.asc()).offset(skip).limit(limit).all()
    return [(u, en) for u, en in filas], total


def cambiar_rol(db: Session, usuario_id: int, nuevo_rol: str, actor: Usuario) -> Usuario:
    rol = permisos.normalizar_rol(nuevo_rol)
    if rol not in permisos.ROLES_VALIDOS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol no permitido. Roles válidos: usuario_utb (Estudiante), "
                   "auxiliar (Auditor), administrador (Administrador)",
        )
    user = _obtener(db, usuario_id)
    if user.id == actor.id:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_A_SI_MISMO)
    anterior = permisos.normalizar_rol(user.rol)
    if anterior == rol:
        return user
    if anterior == Rol.ADMINISTRADOR.value:
        proteger_ultimo_admin(db, user)
    user.rol = rol
    _invalidar_sesiones(user)
    auditoria.registrar(
        db, "usuario.rol", "usuario", user.id, actor_id=actor.id,
        detalle={"usuario": user.nombre, "de": anterior, "a": rol,
                 "de_etiqueta": permisos.etiqueta(anterior), "a_etiqueta": permisos.etiqueta(rol)},
    )
    db.commit()
    db.refresh(user)
    return user


def cambiar_estado(db: Session, usuario_id: int, activo: bool, actor: Usuario) -> Usuario:
    user = _obtener(db, usuario_id)
    if user.id == actor.id:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_A_SI_MISMO)
    if bool(user.activo) == activo:
        return user
    if not activo:
        proteger_ultimo_admin(db, user)
    user.activo = activo
    _invalidar_sesiones(user)
    auditoria.registrar(
        db, "usuario.activar" if activo else "usuario.desactivar", "usuario", user.id,
        actor_id=actor.id, detalle={"usuario": user.nombre},
    )
    db.commit()
    db.refresh(user)
    return user


def ver_usuario(db: Session, usuario_id: int, solicitante: Usuario) -> Usuario:
    """GET /auth/user/{id}: uno mismo, o quien tiene `usuarios.ver` (auditor y administrador)."""
    if usuario_id != solicitante.id and not permisos.tiene(
        solicitante.rol, permisos.Permiso.USUARIOS_VER
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No tienes permiso para ver a otros usuarios.")
    return _obtener(db, usuario_id)
