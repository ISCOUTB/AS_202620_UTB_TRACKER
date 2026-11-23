"""
Servicio de autenticación — capa de lógica de negocio (S9, ADR-0014).

Registro con correo por verificar, login por nombre o correo, sesión con tokens por id,
verificación de correo y recuperación de contraseña con tokens de un solo uso, límites de
frecuencia en base de datos y auditoría de cada acción sensible (ADR-0010).
"""
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core import config
from app.core.deps import sesion_vigente, usuario_de_sujeto
from app.core.hashing import hash_password, verify_password
from app.core.politica import error_password, normalizar_correo, normalizar_nombre
from app.core.security import (
    PROPOSITO_CAMBIAR_CORREO,
    PROPOSITO_RECUPERAR,
    PROPOSITO_VERIFICAR,
    create_access_token,
    create_refresh_token,
    crear_token_proposito,
    leer_refresh_token,
    leer_token_proposito,
)
from app.models.auth_models import Usuario
from app.models.seguridad_models import TokenUsado
from app.schemas.auth import UsuarioCreate, UsuarioLogin
from app.services import asignaciones, auditoria, correo, limites

logger = logging.getLogger("utb_tracker")

# Constante reutilizable — evita duplicación del literal (SonarCloud: design)
_MSG_USUARIO_NO_ENCONTRADO = "Usuario no encontrado"
MSG_TOKEN_INVALIDO = "El enlace o código no es válido, ya se usó o venció. Pide uno nuevo."
MSG_LIMITE_CORREO = "Ya te enviamos varios correos. Espera unos minutos antes de pedir otro."


def _ahora() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _buscar_por_nombre(db: Session, nombre: str) -> Optional[Usuario]:
    nombre = normalizar_nombre(nombre)
    return db.query(Usuario).filter(func.lower(Usuario.nombre) == nombre.lower()).first()


def buscar_por_correo(db: Session, correo_: str) -> Optional[Usuario]:
    """Busca sin distinguir mayúsculas (cubre filas antiguas aún no normalizadas)."""
    correo_ = normalizar_correo(correo_)
    return db.query(Usuario).filter(func.lower(Usuario.email) == correo_).first()


def emitir_tokens(user: Usuario) -> dict:
    """Par de tokens de sesión con `sub` = id y la versión de sesión actual (ADR-0014)."""
    sujeto = {"sub": user.id, "sv": getattr(user, "sesion_version", 0) or 0}
    return {
        "access_token": create_access_token(sujeto),
        "refresh_token": create_refresh_token(sujeto),
        "token_type": "bearer",
    }


# --------------------------------------------------------------------------
# Tokens de un solo uso
# --------------------------------------------------------------------------
def consumir_token(db: Session, token: str, proposito: str) -> tuple[dict, Usuario]:
    """Valida el token, comprueba que no se haya usado y lo marca como usado (en la sesión).

    Si el token es malo, ya se usó, venció o es de otro propósito: 400 con mensaje neutro.
    """
    payload = leer_token_proposito(token, proposito)
    if payload is None or db.get(TokenUsado, payload["jti"]) is not None:
        raise HTTPException(status_code=400, detail=MSG_TOKEN_INVALIDO)
    user = db.get(Usuario, int(payload["sub"]))
    if user is None or not user.activo:
        raise HTTPException(status_code=400, detail=MSG_TOKEN_INVALIDO)
    db.add(TokenUsado(
        jti=payload["jti"],
        proposito=proposito,
        usuario_id=user.id,
        usado_en=_ahora(),
        expira_en=datetime.fromtimestamp(payload["exp"], tz=timezone.utc).replace(tzinfo=None),
    ))
    return payload, user


def _enlace(ruta: str, token: str) -> str:
    return f"{config.URL_PUBLICA}{ruta}?token={token}"


def _encolar_verificacion(db: Session, user: Usuario) -> None:
    token = crear_token_proposito(user.id, PROPOSITO_VERIFICAR)
    correo.encolar(db, user.email, "verificacion", {
        "nombre": user.nombre,
        "enlace": _enlace("/auth/verificar-correo", token),
        "horas": config.VERIFICACION_EXPIRA_HORAS,
    }, usuario_id=user.id)


# --------------------------------------------------------------------------
# Registro y verificación
# --------------------------------------------------------------------------
def create_user(db: Session, schema: UsuarioCreate) -> Usuario:
    """
    Registra un nuevo usuario SIN verificar y deja en el outbox el correo de verificación
    (misma transacción). La contraseña se almacena como hash bcrypt (QS-04 / ADR-0004).
    Valida duplicados por nombre y por correo, sin distinguir mayúsculas (ADR-0014).
    """
    if _buscar_por_nombre(db, schema.nombre):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese nombre de usuario ya está en uso. Elige otro.",
        )
    if buscar_por_correo(db, schema.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya hay una cuenta con ese correo. Inicia sesión o recupera tu contraseña.",
        )

    # El registro SIEMPRE nace con el rol base: el cliente no elige rol (ADR-0019). Un rol de la
    # lista de asignaciones solo se aplica cuando la persona COMPRUEBA su correo (verificar).
    rol = asignaciones.ROL_BASE

    try:
        new_user = Usuario(
            nombre=schema.nombre,
            email=schema.email,
            rol=rol,
            rol_manual=False,
            password=hash_password(schema.password),  # hash bcrypt — S9 req. 9.8
            # Sin correo real en producción la cuenta nace verificada (config.VERIFICACION_OBLIGATORIA).
            email_verificado=not config.VERIFICACION_OBLIGATORIA,
        )
        db.add(new_user)
        db.flush()
        auditoria.registrar(
            db, "usuario.registro", "usuario", new_user.id, actor_id=new_user.id,
            detalle={"rol": rol},
        )
        if config.VERIFICACION_OBLIGATORIA:
            _encolar_verificacion(db, new_user)
            limites.anotar(db, f"reenvio:{new_user.id}")
        db.commit()
        db.refresh(new_user)
        return new_user
    except IntegrityError as exc:
        # Dos registros simultáneos con el mismo correo: lo frena el índice único.
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya hay una cuenta con ese correo o nombre de usuario.",
        ) from exc
    except Exception as exc:
        db.rollback()
        logger.exception("Error inesperado al crear usuario")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno al crear usuario",
        ) from exc


def verificar_correo(db: Session, token: str) -> Usuario:
    """Marca el correo como verificado (token de un solo uso) y envía la bienvenida."""
    _, user = consumir_token(db, token, PROPOSITO_VERIFICAR)
    if not user.email_verificado or not user.email_verificado_en:
        user.email_verificado = True
        user.email_verificado_en = _ahora()
        auditoria.registrar(db, "usuario.verificar_correo", "usuario", user.id, actor_id=user.id)
        correo.encolar(db, user.email, "bienvenida", {"nombre": user.nombre}, usuario_id=user.id)
    asignaciones.recalcular(db, user, "correo_verificado", actor_id=user.id)
    db.commit()
    return user


def abrir_enlace_correo(db: Session, token: str) -> tuple[str, Usuario]:
    """El enlace de los correos sirve para verificar la cuenta o para confirmar un cambio de
    correo (Fase 2): el claim `proposito` del token decide cuál."""
    if leer_token_proposito(token, PROPOSITO_CAMBIAR_CORREO):
        from app.services import perfil  # import tardío: perfil usa este módulo

        return "cambio", perfil.confirmar_cambio_correo(db, token)
    return "verificacion", verificar_correo(db, token)


def reenviar_verificacion(db: Session, user: Usuario, ip: str) -> None:
    """Reenvía el correo de verificación (máx. CORREO_RATE_LIMIT por ventana, por cuenta e IP)."""
    if user.email_verificado:
        raise HTTPException(status_code=409, detail="Tu correo ya está verificado.")
    for clave in (f"reenvio:{user.id}", f"reenvio-ip:{ip}"):
        limites.exigir(db, clave, config.CORREO_RATE_LIMIT,
                       config.CORREO_RATE_WINDOW_SECONDS, MSG_LIMITE_CORREO)
    _encolar_verificacion(db, user)
    limites.anotar(db, f"reenvio:{user.id}")
    limites.anotar(db, f"reenvio-ip:{ip}")
    auditoria.registrar(db, "usuario.reenviar_verificacion", "usuario", user.id, actor_id=user.id)
    db.commit()


# --------------------------------------------------------------------------
# Inicio de sesión y sesión
# --------------------------------------------------------------------------
def login(db: Session, schema: UsuarioLogin, ip: str = "desconocida") -> dict:
    """
    Autentica al usuario por nombre de usuario O correo, y contraseña.
    Retorna tokens JWT junto con datos del usuario para evitar
    que el frontend necesite hacer peticiones adicionales.
    El mensaje de error es el mismo exista o no la cuenta.
    """
    ident = schema.nombre.strip()
    clave = f"login:{ip}:{ident.lower()}"[:255]
    limites.exigir(db, clave, config.LOGIN_RATE_LIMIT, config.LOGIN_RATE_WINDOW_SECONDS,
                   "Demasiados intentos. Intenta más tarde.")

    user = buscar_por_correo(db, ident) if "@" in ident else _buscar_por_nombre(db, ident)
    if user is None or not verify_password(schema.password, user.password):
        # Nunca se guarda la contraseña intentada: solo el identificador que se probó.
        limites.anotar(db, clave)
        if user is not None:
            limites.anotar(db, f"login-fallido:{user.id}")
        auditoria.registrar_y_confirmar(
            db, "auth.login_fallido", "usuario", user.id if user else None,
            detalle={"nombre_intentado": ident[:120]},  # usuario o correo escrito
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario, correo o contraseña incorrectos",
        )
    if hasattr(user, "activo") and not user.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta desactivada",
        )

    # Alerta si se entra justo después de varios intentos fallidos sobre ESTA cuenta.
    fallidos = limites.contar(db, f"login-fallido:{user.id}", config.LOGIN_RATE_WINDOW_SECONDS)
    if fallidos >= 3:
        correo.encolar(db, user.email, "inicio_sesion_sospechoso", {
            "nombre": user.nombre,
            "fecha": datetime.now(timezone(timedelta(hours=-5))).strftime("%d/%m/%Y %I:%M %p"),
            "fallidos": fallidos,
        }, usuario_id=user.id)
    limites.limpiar(db, clave)
    limites.limpiar(db, f"login-fallido:{user.id}")
    # Si la lista de asignaciones cambió, el rol se pone al día aquí (los tokens que se emiten
    # abajo ya llevan la versión de sesión nueva).
    asignaciones.recalcular(db, user, "inicio_sesion", actor_id=user.id)
    auditoria.registrar(db, "auth.login", "usuario", user.id, actor_id=user.id,
                        detalle={"tras_fallidos": fallidos} if fallidos else None)
    db.commit()
    return {**emitir_tokens(user), "user": user}


def refresh_access_token(db: Session, refresh_token: str) -> dict:
    sujeto = leer_refresh_token(refresh_token)
    user = usuario_de_sujeto(db, sujeto) if sujeto else None
    if sujeto is None or user is None or not sesion_vigente(user, sujeto):
        raise HTTPException(status_code=401, detail="Refresh token inválido o expirado")
    if hasattr(user, "activo") and not user.activo:
        raise HTTPException(status_code=403, detail="Cuenta desactivada")
    return emitir_tokens(user)


def update_fcm_token(db: Session, user: Usuario, fcm_token: str) -> None:
    user.fcm_token = fcm_token
    db.commit()


# --------------------------------------------------------------------------
# Recuperación de contraseña
# --------------------------------------------------------------------------
def request_password_reset(db: Session, email: str, ip: str = "desconocida") -> None:
    """Deja en el outbox el correo de recuperación con un token de un solo uso.

    La respuesta HTTP es la misma exista o no el correo (no revela cuentas). El límite por
    correo y por IP evita usar este endpoint para llenar de correos a alguien. Un correo no
    institucional solo recibe algo si es de una cuenta ANTIGUA (ADR-0019: no se bloquea a nadie).
    """
    email = normalizar_correo(email)
    for clave in (f"recuperar:{email}", f"recuperar-ip:{ip}"):
        limites.exigir(db, clave, config.CORREO_RATE_LIMIT,
                       config.CORREO_RATE_WINDOW_SECONDS, MSG_LIMITE_CORREO)
    limites.anotar(db, f"recuperar:{email}")
    limites.anotar(db, f"recuperar-ip:{ip}")
    user = buscar_por_correo(db, email)
    if user and user.activo:
        token = crear_token_proposito(user.id, PROPOSITO_RECUPERAR)
        correo.encolar(db, user.email, "recuperacion", {
            "nombre": user.nombre,
            "enlace": _enlace("/auth/restablecer", token),
            "codigo": token,
            "minutos": config.RECUPERACION_EXPIRA_MINUTOS,
        }, usuario_id=user.id)
        auditoria.registrar(db, "auth.recuperacion_solicitada", "usuario", user.id)
    db.commit()


def aplicar_nueva_password(db: Session, user: Usuario, nueva: str) -> None:
    """Política + hash + cierra las demás sesiones + aviso por correo (en la sesión actual)."""
    error = error_password(nueva, user.email, user.nombre)
    if error:
        raise HTTPException(status_code=422, detail=error)
    user.password = hash_password(nueva)
    if hasattr(user, "sesion_version"):
        user.sesion_version = (user.sesion_version or 0) + 1
    correo.encolar(db, user.email, "cambio_password", {
        "nombre": user.nombre,
        "fecha": datetime.now(timezone(timedelta(hours=-5))).strftime("%d/%m/%Y %I:%M %p"),
    }, usuario_id=user.id)


def reset_password(db: Session, token: str, new_password: str) -> None:
    _, user = consumir_token(db, token, PROPOSITO_RECUPERAR)
    aplicar_nueva_password(db, user, new_password)
    # Quien recibió el enlace demostró poseer el correo.
    if not user.email_verificado or not user.email_verificado_en:
        user.email_verificado = True
        user.email_verificado_en = _ahora()
    auditoria.registrar(db, "auth.recuperar_password", "usuario", user.id, actor_id=user.id)
    asignaciones.recalcular(db, user, "correo_comprobado", actor_id=user.id)
    db.commit()


# --------------------------------------------------------------------------
# Administración de usuarios (panel)
# --------------------------------------------------------------------------
def delete_user(db: Session, user_id: int, actor: Usuario) -> dict:
    """DELETE /auth/delete/{id} (legado): desactiva con las mismas reglas que el panel."""
    from app.services import usuarios
    usuarios.cambiar_estado(db, user_id, False, actor)
    return {"message": "Usuario desactivado correctamente"}


def get_user_by_id(db: Session, user_id: int) -> Usuario:
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=_MSG_USUARIO_NO_ENCONTRADO
        )
    return user


def get_me(db: Session, email: str) -> Usuario:
    """Obtiene un usuario a partir de su email (sin distinguir mayúsculas)."""
    user = buscar_por_correo(db, email)
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


def update_user_role(db: Session, user_id: int, new_role: str, actor: Usuario) -> Usuario:
    """PATCH/PUT /auth/user/{id}/role (legado): mismas reglas que PATCH /usuarios/{id}/rol."""
    from app.services import usuarios
    return usuarios.cambiar_rol(db, user_id, new_role, actor)
