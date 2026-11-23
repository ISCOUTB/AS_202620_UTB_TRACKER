"""
Servicio de perfil de la cuenta propia (ADR-0014): cambio de correo directo (ADR-0024),
edición del perfil, contraseña, sesiones y preferencias. Todo queda auditado (ADR-0010).
"""
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core import config
from app.core.hashing import verify_password
from app.core.politica import error_correo_nuevo, normalizar_correo
from app.models.auth_models import Usuario
from app.schemas.perfil import PerfilResponse, PerfilUpdate, Preferencias
from app.services import asignaciones, auditoria, correo, fotos, limites
from app.services.usuarios import proteger_ultimo_admin
from app.services.auth import (
    MSG_LIMITE_CORREO,
    aplicar_nueva_password,
    buscar_por_correo,
    emitir_tokens,
)

MSG_CLAVE_ACTUAL = "La contraseña actual no es correcta."
MSG_CORREO_EN_USO = "Ese correo ya está en uso en otra cuenta."
_INTENTOS_PASSWORD = 5


def exigir_password(db: Session, user: Usuario, password: str) -> None:
    """Confirma una acción sensible con la contraseña actual (con límite de intentos)."""
    clave = f"password-actual:{user.id}"
    limites.exigir(db, clave, _INTENTOS_PASSWORD, config.LOGIN_RATE_WINDOW_SECONDS,
                   "Demasiados intentos con la contraseña actual. Espera unos minutos.")
    if not verify_password(password or "", user.password):
        limites.anotar(db, clave)
        db.commit()
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=MSG_CLAVE_ACTUAL)
    limites.limpiar(db, clave)


# --------------------------------------------------------------------------
# Datos del perfil y preferencias
# --------------------------------------------------------------------------
def respuesta(db: Session, user: Usuario) -> PerfilResponse:
    """GET/PATCH /auth/me: el perfil con lo que se calcula (origen del rol y cargo)."""
    perfil = PerfilResponse.model_validate(user)
    perfil.rol_origen, perfil.cargo = asignaciones.origen(db, user)
    perfil.rol_origen_texto = asignaciones.TEXTO_ORIGEN[perfil.rol_origen]
    perfil.foto_version = fotos.version_de(db, user.id) or 0
    perfil.tiene_foto = perfil.foto_version > 0
    return perfil


_CAMPOS_PERFIL = ("nombre_mostrar", "telefono", "dependencia", "color_avatar")


def actualizar_perfil(db: Session, user: Usuario, datos: PerfilUpdate) -> Usuario:
    """Cambia solo los campos enviados. En la auditoría van los NOMBRES de los campos, no los
    valores (el teléfono es dato personal)."""
    enviados = datos.model_dump(exclude_unset=True)
    cambiados: list[str] = []
    for campo in _CAMPOS_PERFIL:
        if campo in enviados:
            valor = enviados[campo] or None  # "" borra el campo
            if getattr(user, campo) != valor:
                setattr(user, campo, valor)
                cambiados.append(campo)
    if "preferencias" in enviados and datos.preferencias is not None:
        nuevas = datos.preferencias.model_dump()
        if Preferencias.de(user.preferencias).model_dump() != nuevas:
            user.preferencias = nuevas
            cambiados.append("preferencias")
    if cambiados:
        auditoria.registrar(db, "usuario.perfil", "usuario", user.id, actor_id=user.id,
                            detalle={"campos": cambiados})
        db.commit()
        db.refresh(user)
    return user


# --------------------------------------------------------------------------
# Contraseña, sesiones y desactivación
# --------------------------------------------------------------------------
def cambiar_password(db: Session, user: Usuario, actual: str, nueva: str) -> dict:
    """Pide la actual, aplica la política, avisa por correo y cierra las DEMÁS sesiones: sube
    la versión de sesión y devuelve tokens nuevos para este dispositivo."""
    exigir_password(db, user, actual)
    if actual == nueva:
        raise HTTPException(status_code=422, detail="La contraseña nueva debe ser distinta de la actual.")
    aplicar_nueva_password(db, user, nueva)
    auditoria.registrar(db, "usuario.cambiar_password", "usuario", user.id, actor_id=user.id)
    db.commit()
    db.refresh(user)
    return {"message": "Contraseña actualizada. Se cerraron las demás sesiones.", **emitir_tokens(user)}


def cerrar_sesiones(db: Session, user: Usuario) -> dict:
    """Cierra la sesión en todos los demás dispositivos (los tokens viejos dejan de valer)."""
    user.sesion_version = (user.sesion_version or 0) + 1
    auditoria.registrar(db, "usuario.cerrar_sesiones", "usuario", user.id, actor_id=user.id)
    db.commit()
    db.refresh(user)
    return {"message": "Cerramos tu sesión en los demás dispositivos.", **emitir_tokens(user)}


def desactivar_cuenta(db: Session, user: Usuario, password: str) -> None:
    """La persona desactiva su propia cuenta (no se borra: queda para la auditoría)."""
    exigir_password(db, user, password)
    proteger_ultimo_admin(db, user)  # nunca sin administrador activo (ADR-0018)
    user.activo = False
    user.sesion_version = (user.sesion_version or 0) + 1
    fotos.borrar_contenido(db, user.id)  # la foto es dato personal: no se conserva (ADR-0020)
    auditoria.registrar(db, "usuario.desactivar_propia", "usuario", user.id, actor_id=user.id)
    db.commit()


def cambiar_correo(db: Session, user: Usuario, nuevo: str, password: str, ip: str) -> Usuario:
    """Cambia el correo al instante (ADR-0024: sin verificación; el dominio institucional ya es
    de la UTB). Pide la contraseña, limita los intentos y avisa al correo anterior. El rol NO
    depende del correo, así que cambiarlo nunca da ni quita permisos."""
    exigir_password(db, user, password)
    nuevo = normalizar_correo(nuevo)
    error = error_correo_nuevo(nuevo)  # solo institucionales (ADR-0019)
    if error:
        raise HTTPException(status_code=422, detail=error)
    if nuevo == normalizar_correo(user.email):
        raise HTTPException(status_code=409, detail="Ese ya es tu correo.")
    if buscar_por_correo(db, nuevo):
        raise HTTPException(status_code=409, detail=MSG_CORREO_EN_USO)
    for clave in (f"cambio-correo:{user.id}", f"cambio-correo-ip:{ip}"):
        limites.exigir(db, clave, config.CORREO_RATE_LIMIT,
                       config.CORREO_RATE_WINDOW_SECONDS, MSG_LIMITE_CORREO)
    limites.anotar(db, f"cambio-correo:{user.id}")
    limites.anotar(db, f"cambio-correo-ip:{ip}")
    anterior = user.email
    user.email = nuevo
    correo.encolar(db, anterior, "cambio_correo_aviso", {
        "nombre": user.nombre,
        "correo_nuevo_oculto": correo.ocultar_correo(nuevo),
    }, usuario_id=user.id)
    auditoria.registrar(db, "usuario.cambio_correo", "usuario", user.id, actor_id=user.id,
                        detalle={"de": correo.ocultar_correo(anterior),
                                 "a": correo.ocultar_correo(nuevo)})
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail=MSG_CORREO_EN_USO) from exc
    db.refresh(user)
    return user
