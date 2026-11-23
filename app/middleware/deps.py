"""
Dependencias de autenticación y autorización para la API.

Provee resolución del usuario autenticado a partir de tokens JWT
y control de acceso por PERMISOS (tabla única en app/middleware/permisos.py, ADR-0018).
"""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.middleware import permisos
from app.db.database import get_db
from app.middleware.permisos import Permiso
from app.middleware.security import Sujeto, leer_access_token
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


def require_permiso(permiso: Permiso):
    """
    Fábrica de dependencias: exige un permiso de `app/middleware/permisos.py` (ADR-0018).
    Uso: `Depends(require_permiso(Permiso.SALONES_ADMINISTRAR))`. 401 sin sesión, 403 sin permiso.
    """
    def verificar_permiso(
        current_user: Annotated[Usuario, Depends(get_current_user)],
    ) -> Usuario:
        if not permisos.tiene(current_user.rol, permiso):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para hacer esto.",
            )
        return current_user

    verificar_permiso.permiso = permiso  # la prueba de matriz lo lee
    return verificar_permiso


def con_permiso(permiso: Permiso):
    """Alias de tipo: `current_user: Con(Permiso.EQUIPOS_GESTIONAR)`."""
    return Annotated[Usuario, Depends(require_permiso(permiso))]


# Alias para retrocompatibilidad
Con = con_permiso

# Alias de tipo para patrones comunes de inyección
CurrentUser = Annotated[Usuario, Depends(get_current_user)]

# Un alias por permiso (nombre = lo que la persona puede hacer). Los routers solo usan estos.
VeSalones = con_permiso(Permiso.SALONES_VER)
SolicitaSalon = con_permiso(Permiso.SALONES_SOLICITAR)
TieneSolicitudes = con_permiso(Permiso.SOLICITUDES_PROPIAS)
CreaReportes = con_permiso(Permiso.REPORTES_CREAR)
VeEquipos = con_permiso(Permiso.EQUIPOS_VER)
VeHorarios = con_permiso(Permiso.HORARIOS_VER)
GestionaSolicitudes = con_permiso(Permiso.SOLICITUDES_GESTIONAR)
AdministraSalones = con_permiso(Permiso.SALONES_ADMINISTRAR)
GestionaReportes = con_permiso(Permiso.REPORTES_GESTIONAR)
GestionaEquipos = con_permiso(Permiso.EQUIPOS_GESTIONAR)
GestionaHorarios = con_permiso(Permiso.HORARIOS_GESTIONAR)
GestionaCatalogo = con_permiso(Permiso.SALONES_CREAR_CATALOGO)
GestionaUsuarios = con_permiso(Permiso.USUARIOS_GESTIONAR)
VeAuditoria = con_permiso(Permiso.AUDITORIA_VER)
VeEstadisticas = con_permiso(Permiso.ESTADISTICAS_VER)
