"""
Servicio de autenticación — capa de lógica de negocio (S9).

Gestiona el registro, verificación de credenciales, generación de tokens
y consulta del perfil de usuario autenticado.
"""
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.hashing import hash_password, verify_password
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_reset_password_token,
    verify_reset_password_token,
    verify_refresh_token,
)
from app.messaging.models import MensajeOutbox
from datetime import datetime, timezone
import json
import uuid
from app.models.auth_models import Usuario
from app.schemas.auth import UsuarioCreate, UsuarioLogin

# Constante reutilizable — evita duplicación del literal (SonarCloud: design)
_MSG_USUARIO_NO_ENCONTRADO = "Usuario no encontrado"


def create_user(db: Session, schema: UsuarioCreate) -> Usuario:
    """
    Registra un nuevo usuario. La contraseña se almacena como hash bcrypt,
    nunca en texto plano (QS-04 / ADR-0004).
    Valida duplicados por nombre Y por email.
    """
    # Verificar nombre duplicado
    existente = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un usuario con ese nombre",
        )
    # Verificar email duplicado
    existente_email = db.query(Usuario).filter(Usuario.email == schema.email).first()
    if existente_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un usuario con ese email",
        )

    # El registro público SIEMPRE asigna el rol base 'usuario_utb'.
    # La asignación de roles privilegiados (auxiliar, administrador) solo es permitida
    # desde el panel administrativo.
    rol = "usuario_utb"

    try:
        new_user = Usuario(
            nombre=schema.nombre,
            email=schema.email,
            rol=rol,
            password=hash_password(schema.password),  # hash bcrypt — S9 req. 9.8
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al crear usuario",
        )


def login(db: Session, schema: UsuarioLogin) -> dict:
    """
    Autentica al usuario por nombre y contraseña.
    Retorna token JWT junto con datos del usuario para evitar
    que el frontend necesite hacer peticiones adicionales.
    """
    user = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if user is None or not verify_password(schema.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nombre de usuario o contraseña incorrectos",
        )
    if hasattr(user, "activo") and not user.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta desactivada",
        )
    token = create_access_token({"sub": user.email})
    refresh_token = create_refresh_token({"sub": user.email})
    return {
        "access_token": token,
        "token_type": "bearer",
        "refresh_token": refresh_token,
        "user": {
            "id": user.id,
            "nombre": user.nombre,
            "email": user.email,
            "rol": user.rol,
        },
    }


def refresh_access_token(db: Session, refresh_token: str) -> dict:
    email = verify_refresh_token(refresh_token)
    if not email:
        raise HTTPException(status_code=401, detail="Refresh token inválido o expirado")
    user = get_me(db, email)
    if hasattr(user, "activo") and not user.activo:
        raise HTTPException(status_code=403, detail="Cuenta desactivada")
    return {
        "access_token": create_access_token({"sub": user.email}),
        "refresh_token": create_refresh_token({"sub": user.email}),
        "token_type": "bearer",
    }


def update_fcm_token(db: Session, user: Usuario, fcm_token: str) -> None:
    user.fcm_token = fcm_token
    db.commit()


def delete_user(db: Session, user_id: int) -> dict:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    try:
        # Soft-delete: marcar como inactivo en vez de borrar
        if hasattr(user, "activo"):
            user.activo = False
            db.commit()
            return {"message": "Usuario desactivado correctamente"}
        else:
            db.delete(user)
            db.commit()
            return {"message": "Usuario eliminado correctamente"}
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al eliminar usuario",
        )


def get_user_by_id(db: Session, user_id: int) -> Usuario:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    return user


def get_me(db: Session, email: str) -> Usuario:
    """Obtiene el usuario actual a partir de su email (extraído del JWT)."""
    user = db.query(Usuario).filter(Usuario.email == email).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    return user


def logout(db: Session, user_id: int) -> dict:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    return {"message": "Cierre de sesión exitoso"}


def get_all_users(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    rol: Optional[str] = None,
) -> list[Usuario]:
    """
    Lista usuarios registrados para el panel administrativo.
    Permite filtrar por texto de búsqueda (nombre o correo) y por rol.
    """
    query = db.query(Usuario)
    if search:
        termino = f"%{search.strip()}%"
        query = query.filter(
            (Usuario.nombre.ilike(termino)) | (Usuario.email.ilike(termino))
        )
    if rol:
        query = query.filter(Usuario.rol == rol.strip().lower())
    return query.order_by(Usuario.id.asc()).offset(skip).limit(limit).all()


def update_user_role(db: Session, user_id: int, new_role: str) -> Usuario:
    """
    Actualiza el rol de un usuario desde el panel administrativo.
    Roles válidos: usuario_utb, auxiliar, administrador.
    """
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )

    rol_normalizado = new_role.strip().lower()
    if rol_normalizado not in ("usuario_utb", "administrador", "auxiliar"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol no permitido. Roles válidos: usuario_utb, auxiliar, administrador",
        )

    try:
        user.rol = rol_normalizado
        db.commit()
        db.refresh(user)
        return user
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al actualizar rol de usuario",
        )


def request_password_reset(db: Session, email: str) -> None:
    """Genera un token de corta duración y lo entrega mediante el outbox.

    La respuesta HTTP deliberadamente no revela si el correo existe.
    """
    user = db.query(Usuario).filter(Usuario.email == email).first()
    if not user:
        return
    token = create_reset_password_token(user.email)
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    db.add(MensajeOutbox(
        message_id=str(uuid.uuid4()),
        tipo="password.reset solicitado",
        version=1,
        payload=json.dumps({"email": user.email, "token": token}),
        correlation_id=None,
        estado="pendiente",
        siguiente_intento=now,
        creado_en=now,
    ))
    db.commit()


def reset_password(db: Session, token: str, new_password: str) -> None:
    email = verify_reset_password_token(token)
    if not email:
        raise HTTPException(status_code=400, detail="Token de recuperación inválido o expirado")
    user = db.query(Usuario).filter(Usuario.email == email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Token de recuperación inválido o expirado")
    user.password = hash_password(new_password)
    db.commit()
