"""
Servicio de autenticación — capa de lógica de negocio (S9).

Gestiona el registro, verificación de credenciales, generación de tokens
y consulta del perfil de usuario autenticado.
"""
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.hashing import hash_password, verify_password
from app.core.security import create_access_token
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
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "nombre": user.nombre,
            "email": user.email,
            "rol": user.rol,
        },
    }


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
