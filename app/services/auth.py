"""
Servicio de autenticación — capa de lógica de negocio (S9).

Correcciones S9:
  - 9.7: Corregido bug user.correo → user.email (AttributeError en login).
  - 9.8: Contraseñas almacenadas con hashing bcrypt (passlib) — nunca texto plano.
  - 9.6: Este módulo implementa la capa de servicio de auth, manteniendo
    coherencia con el patrón que ya usaba auth antes (a diferencia de loans
    y resources que mezclaban BD en el router).
"""
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
    """
    existing = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un usuario con ese nombre",
        )
    try:
        new_user = Usuario(
            nombre=schema.nombre,
            email=schema.email,
            rol=schema.rol,
            password=hash_password(schema.password),  # hash bcrypt — S9 req. 9.8
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


def login(db: Session, schema: UsuarioLogin) -> dict:
    """
    Autentica al usuario por nombre y contraseña.
    Bug corregido S9-9.7: se usa user.email (campo real del modelo), no user.correo.
    Contraseña verificada con bcrypt — S9 req. 9.8.
    """
    user = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if user is None or not verify_password(schema.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nombre de usuario o contraseña incorrectos",
        )
    token = create_access_token({"sub": user.email})  # corregido: user.email (era user.correo)
    return {"access_token": token, "token_type": "bearer"}


def delete_user(db: Session, user_id: int) -> dict:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    try:
        db.delete(user)
        db.commit()
        return {"message": "Usuario eliminado correctamente"}
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


def get_user_by_id(db: Session, user_id: int) -> Usuario:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
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