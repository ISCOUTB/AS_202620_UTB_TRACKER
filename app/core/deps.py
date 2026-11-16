"""
Dependencias de autenticación y autorización para la API.

Provee resolución del usuario autenticado a partir de tokens JWT
y control de acceso por PERMISOS (tabla única en app/core/permisos.py, ADR-0018).
"""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core import permisos
from app.core.database import get_db
from app.core.permisos import Permiso
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


def require_permiso(permiso: Permiso, *, verificado: bool = False):
    """
    Fábrica de dependencias: exige un permiso de `app/core/permisos.py` (ADR-0018).
    Uso: `Depends(require_permiso(Permiso.SALONES_ADMINISTRAR))`. Con `verificado=True`
    además exige correo verificado (ADR-0014). 401 sin sesión, 403 sin permiso.
    """
    def verificar_permiso(
        current_user: Annotated[Usuario, Depends(get_current_user)],
    ) -> Usuario:
        if not permisos.tiene(current_user.rol, permiso):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para hacer esto.",
            )
        if verificado:
            require_verified(current_user)
        return current_user

    verificar_permiso.permiso = permiso  # la prueba de matriz lo lee
    return verificar_permiso


def Con(permiso: Permiso, *, verificado: bool = False):  # noqa: N802 (se usa como un tipo)
    """Alias de tipo: `current_user: Con(Permiso.EQUIPOS_GESTIONAR)`."""
    return Annotated[Usuario, Depends(require_permiso(permiso, verificado=verificado))]


# Alias de tipo para patrones comunes de inyección
CurrentUser = Annotated[Usuario, Depends(get_current_user)]
VerifiedUser = Annotated[Usuario, Depends(require_verified)]

# Un alias por permiso (nombre = lo que la persona puede hacer). Los routers solo usan estos.
VeSalones = Con(Permiso.SALONES_VER)
SolicitaSalon = Con(Permiso.SALONES_SOLICITAR, verificado=True)
TieneSolicitudes = Con(Permiso.SOLICITUDES_PROPIAS)
CreaReportes = Con(Permiso.REPORTES_CREAR)
VeEquipos = Con(Permiso.EQUIPOS_VER)
VeHorarios = Con(Permiso.HORARIOS_VER)
GestionaSolicitudes = Con(Permiso.SOLICITUDES_GESTIONAR)
AdministraSalones = Con(Permiso.SALONES_ADMINISTRAR)
GestionaReportes = Con(Permiso.REPORTES_GESTIONAR)
GestionaEquipos = Con(Permiso.EQUIPOS_GESTIONAR)
GestionaHorarios = Con(Permiso.HORARIOS_GESTIONAR)
GestionaUsuarios = Con(Permiso.USUARIOS_GESTIONAR)
VeAuditoria = Con(Permiso.AUDITORIA_VER)
VeEstadisticas = Con(Permiso.ESTADISTICAS_VER)
