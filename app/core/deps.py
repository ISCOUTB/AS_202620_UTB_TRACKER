"""
Dependencias de autenticación y autorización para la API.

Provee resolución del usuario autenticado a partir de tokens JWT
y control de acceso basado en roles para los endpoints.
"""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import Sujeto, leer_access_token
from app.models.auth_models import Usuario

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def get_current_user(
    token: Annotated[str | None, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> Usuario:
    """
    Dependencia de FastAPI que extrae el usuario autenticado del token JWT.
    Lanza 401 si el token es inválido o el usuario no existe.
    """
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación requerido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    sujeto = leer_access_token(token)
    user = usuario_de_sujeto(db, sujeto) if sujeto else None
    if sujeto is None or (user is not None and not sesion_vigente(user, sujeto)):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if hasattr(user, "activo") and not user.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta desactivada",
        )

    return user


def usuario_de_sujeto(db: Session, sujeto: Sujeto) -> Usuario | None:
    """El `sub` es el id (tokens nuevos) o el correo (tokens emitidos antes de ADR-0014)."""
    if sujeto.usuario_id is not None:
        return db.query(Usuario).filter(Usuario.id == sujeto.usuario_id).first()
    return db.query(Usuario).filter(func.lower(Usuario.email) == (sujeto.email or "").lower()).first()


def sesion_vigente(user: Usuario, sujeto: Sujeto) -> bool:
    """Un token emitido antes del último "cerrar todas las sesiones" ya no vale."""
    return sujeto.version_sesion >= (getattr(user, "sesion_version", 0) or 0)


def require_verified(
    current_user: Annotated[Usuario, Depends(get_current_user)],
) -> Usuario:
    """Acciones que exigen correo verificado (p. ej. solicitar un salón). ADR-0014."""
    if not current_user.email_verificado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Verifica tu correo para hacer esto. Revisa tu bandeja o pide que te lo reenviemos.",
        )
    return current_user


def require_role(*roles: str):
    """
    Fábrica de dependencias para restringir acceso por rol.
    Uso: Depends(require_role("administrador", "auxiliar"))
    """
    def role_checker(
        current_user: Annotated[Usuario, Depends(get_current_user)],
    ) -> Usuario:
        if current_user.rol not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Se requiere rol: {', '.join(roles)}",
            )
        return current_user
    return role_checker


# Alias de tipo para patrones comunes de inyección
CurrentUser = Annotated[Usuario, Depends(get_current_user)]
VerifiedUser = Annotated[Usuario, Depends(require_verified)]
AdminUser = Annotated[Usuario, Depends(require_role("administrador", "auxiliar"))]
# La bitácora de auditoría solo la ve el administrador (el auxiliar opera, no supervisa).
SoloAdministrador = Annotated[Usuario, Depends(require_role("administrador"))]
