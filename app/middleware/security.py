"""
Tokens JWT (ADR-0004, ADR-0014).

Sesión (access / refresh):
  - `sub` = id del usuario (texto). Antes era el correo, y al cambiar el correo se rompían las
    sesiones abiertas. Los tokens viejos con correo en `sub` se siguen aceptando mientras vivan
    (como máximo REFRESH_TOKEN_EXPIRE_DAYS después del despliegue).
  - `sv` = versión de sesión del usuario. Cambiar la contraseña o "cerrar sesión en todos los
    dispositivos" sube la versión y deja inválidos los tokens emitidos antes.

Un solo uso (recuperar contraseña):
  - claim `proposito` + `jti` aleatorio; el `jti` se anota en tokens_usados al usarlo.
  - Cada propósito se firma con un secreto distinto: un token de verificación no sirve para
    recuperar la contraseña ni para iniciar sesión.
"""
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional

import jwt

from app.config.config import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM,
    FORGET_PWD_SECRET_KEY,
    RECUPERACION_EXPIRA_MINUTOS,
    REFRESH_TOKEN_EXPIRE_DAYS,
    SECRET_KEY,
)

PROPOSITO_RECUPERAR = "recuperar_password"

_SECRETOS = {
    PROPOSITO_RECUPERAR: FORGET_PWD_SECRET_KEY,
}
_DURACION = {
    PROPOSITO_RECUPERAR: timedelta(minutes=RECUPERACION_EXPIRA_MINUTOS),
}


@dataclass(frozen=True)
class Sujeto:
    """Quién es el dueño de un token de sesión."""
    usuario_id: Optional[int] = None
    email: Optional[str] = None  # solo tokens emitidos antes de ADR-0014
    version_sesion: int = 0


def _sujeto_de(data: dict) -> dict:
    """Acepta {"sub": id} o, por compatibilidad, {"sub": correo} y agrega la versión."""
    return {"sub": str(data["sub"]), "sv": int(data.get("sv", 0))}


def create_access_token(data: dict):
    to_encode = _sujeto_de(data)
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict):
    to_encode = _sujeto_de(data)
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh", "jti": uuid.uuid4().hex})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def _leer_sesion(token: str, tipo: str) -> Optional[Sujeto]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.PyJWTError:
        return None
    if payload.get("type", "access") != tipo or "proposito" in payload:
        return None
    sub = str(payload.get("sub") or "")
    if not sub:
        return None
    version = int(payload.get("sv", 0))
    if sub.isdigit():
        return Sujeto(usuario_id=int(sub), version_sesion=version)
    return Sujeto(email=sub, version_sesion=version)


def leer_access_token(token: str) -> Optional[Sujeto]:
    return _leer_sesion(token, "access")


def leer_refresh_token(token: str) -> Optional[Sujeto]:
    return _leer_sesion(token, "refresh")


def verify_token(token: str):
    """Compatibilidad: devuelve el `sub` del access token (id o correo) o None."""
    s = leer_access_token(token)
    if s is None:
        return None
    return str(s.usuario_id) if s.usuario_id is not None else s.email


def verify_refresh_token(token: str):
    s = leer_refresh_token(token)
    if s is None:
        return None
    return str(s.usuario_id) if s.usuario_id is not None else s.email


# --------------------------------------------------------------------------
# Tokens de un solo uso
# --------------------------------------------------------------------------
def crear_token_proposito(usuario_id: int, proposito: str, **extra) -> str:
    ahora = datetime.now(timezone.utc)
    datos = {
        "sub": str(usuario_id),
        "proposito": proposito,
        "jti": uuid.uuid4().hex,
        "iat": ahora,
        "exp": ahora + _DURACION[proposito],
        **extra,
    }
    return jwt.encode(datos, _SECRETOS[proposito], algorithm=ALGORITHM)


def leer_token_proposito(token: str, proposito: str) -> Optional[dict]:
    """Devuelve el payload si el token es válido, no venció y es de ESE propósito."""
    try:
        payload = jwt.decode(
            token, _SECRETOS[proposito], algorithms=[ALGORITHM],
            options={"require": ["exp", "sub", "jti"]},
        )
    except jwt.PyJWTError:
        return None
    if payload.get("proposito") != proposito or not str(payload.get("sub", "")).isdigit():
        return None
    return payload


def create_reset_password_token(usuario_id: int) -> str:
    return crear_token_proposito(usuario_id, PROPOSITO_RECUPERAR)
