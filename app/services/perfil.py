"""
Servicio de perfil de la cuenta propia (ADR-0014): cambio de correo con confirmación, y (Fase 2)
edición del perfil, contraseña, sesiones y preferencias. Todo queda auditado (ADR-0010).
"""
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core import config
from app.core.hashing import verify_password
from app.core.politica import correo_valido, normalizar_correo
from app.core.security import PROPOSITO_CAMBIAR_CORREO, crear_token_proposito
from app.models.auth_models import Usuario
from app.schemas.perfil import PerfilUpdate, Preferencias
from app.services import auditoria, correo, limites
from app.services.auth import (
    MSG_LIMITE_CORREO,
    MSG_TOKEN_INVALIDO,
    aplicar_nueva_password,
    buscar_por_correo,
    consumir_token,
    emitir_tokens,
)

MSG_PASSWORD_ACTUAL = "La contraseña actual no es correcta."
_INTENTOS_PASSWORD = 5


def exigir_password(db: Session, user: Usuario, password: str) -> None:
    """Confirma una acción sensible con la contraseña actual (con límite de intentos)."""
    clave = f"password-actual:{user.id}"
    limites.exigir(db, clave, _INTENTOS_PASSWORD, config.LOGIN_RATE_WINDOW_SECONDS,
                   "Demasiados intentos con la contraseña actual. Espera unos minutos.")
    if not verify_password(password or "", user.password):
        limites.anotar(db, clave)
        db.commit()
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=MSG_PASSWORD_ACTUAL)
    limites.limpiar(db, clave)


# --------------------------------------------------------------------------
# Datos del perfil y preferencias
# --------------------------------------------------------------------------
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
    user.activo = False
    user.sesion_version = (user.sesion_version or 0) + 1
    auditoria.registrar(db, "usuario.desactivar_propia", "usuario", user.id, actor_id=user.id)
    db.commit()


def solicitar_cambio_correo(db: Session, user: Usuario, nuevo: str, password: str, ip: str) -> None:
    """El correo NO cambia todavía: se envía un enlace al nuevo y un aviso al anterior."""
    exigir_password(db, user, password)
    nuevo = normalizar_correo(nuevo)
    if not correo_valido(nuevo):
        raise HTTPException(status_code=422, detail="Escribe un correo válido")
    if nuevo == normalizar_correo(user.email):
        raise HTTPException(status_code=409, detail="Ese ya es tu correo.")
    if buscar_por_correo(db, nuevo):
        raise HTTPException(status_code=409, detail="Ese correo ya está en uso en otra cuenta.")
    for clave in (f"cambio-correo:{user.id}", f"cambio-correo-ip:{ip}"):
        limites.exigir(db, clave, config.CORREO_RATE_LIMIT,
                       config.CORREO_RATE_WINDOW_SECONDS, MSG_LIMITE_CORREO)
    limites.anotar(db, f"cambio-correo:{user.id}")
    limites.anotar(db, f"cambio-correo-ip:{ip}")

    token = crear_token_proposito(
        user.id, PROPOSITO_CAMBIAR_CORREO, correo=nuevo, anterior=normalizar_correo(user.email)
    )
    correo.encolar(db, nuevo, "cambio_correo_nuevo", {
        "nombre": user.nombre,
        "correo_nuevo": nuevo,
        "enlace": f"{config.URL_PUBLICA}/auth/verificar-correo?token={token}",
    }, usuario_id=user.id)
    correo.encolar(db, user.email, "cambio_correo_aviso", {
        "nombre": user.nombre,
        "correo_nuevo_oculto": correo.ocultar_correo(nuevo),
    }, usuario_id=user.id)
    auditoria.registrar(db, "usuario.cambio_correo_solicitado", "usuario", user.id,
                        actor_id=user.id, detalle={"nuevo": correo.ocultar_correo(nuevo)})
    db.commit()


def confirmar_cambio_correo(db: Session, token: str) -> Usuario:
    """Abre el enlace enviado al correo NUEVO: ahí sí cambia (y queda verificado)."""
    payload, user = consumir_token(db, token, PROPOSITO_CAMBIAR_CORREO)
    nuevo = normalizar_correo(payload.get("correo", ""))
    # Si el correo ya cambió por otra vía desde que se pidió, el enlace queda obsoleto.
    if not nuevo or normalizar_correo(user.email) != payload.get("anterior"):
        raise HTTPException(status_code=400, detail=MSG_TOKEN_INVALIDO)
    if buscar_por_correo(db, nuevo):
        raise HTTPException(status_code=409, detail="Ese correo ya está en uso en otra cuenta.")
    anterior = user.email
    user.email = nuevo
    user.email_verificado = True
    user.email_verificado_en = limites._ahora()
    auditoria.registrar(db, "usuario.cambio_correo", "usuario", user.id, actor_id=user.id,
                        detalle={"de": correo.ocultar_correo(anterior),
                                 "a": correo.ocultar_correo(nuevo)})
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Ese correo ya está en uso en otra cuenta.") from exc
    return user
