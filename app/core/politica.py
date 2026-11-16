"""
Reglas de identidad compartidas por schemas y servicios (ADR-0014).

La app Flutter repite exactamente estas reglas y mensajes en
`frontend/lib/core/utils/politica.dart`: si cambias una, cambia la otra.
"""
from typing import Optional

from app.core import config

PASSWORD_MINIMO = 8

MSG_CLAVE_CORTA = f"La contraseña debe tener al menos {PASSWORD_MINIMO} caracteres"
MSG_CLAVE_IGUAL_CORREO = "La contraseña no puede ser igual a tu correo"
MSG_CLAVE_IGUAL_NOMBRE = "La contraseña no puede ser igual a tu nombre de usuario"
MSG_CORREO_INVALIDO = "Escribe un correo válido"
MSG_CORREO_NO_INSTITUCIONAL = (
    f"Usa tu correo institucional de la UTB (termina en @{config.DOMINIO_INSTITUCIONAL})"
)
EJEMPLO_CORREO = f"usuario@{config.DOMINIO_INSTITUCIONAL}"

# Parte antes de la "@" en correos NUEVOS: letras, números y . _ + - (sin puntos al borde ni
# seguidos). Las cuentas antiguas no pasan por aquí.
_CARACTERES_USUARIO = frozenset("abcdefghijklmnopqrstuvwxyz0123456789._+-")
_USUARIO_MAXIMO = 64


def normalizar_correo(correo: str) -> str:
    """Minúsculas y sin espacios: 'Ana@UTB.edu.co ' y 'ana@utb.edu.co' son la misma cuenta."""
    return (correo or "").strip().lower()


def correo_valido(correo: str) -> bool:
    """usuario@dominio.ext: una sola @, sin espacios y un punto dentro del dominio.

    Sin expresión regular, para no tener retroceso costoso con entradas largas.
    """
    # Sin saltos de línea ni comas: evita inyección de cabeceras en el correo saliente.
    if not correo or any(c.isspace() or c in ',;<>"' for c in correo):
        return False
    usuario, arroba, dominio = correo.partition("@")
    if not arroba or not usuario or "@" in dominio:
        return False
    nombre_dominio, punto, extension = dominio.rpartition(".")
    return bool(punto and nombre_dominio and extension)


def dominio_de(correo: str) -> str:
    """Lo que va tras la ÚLTIMA "@" (normalizado)."""
    return normalizar_correo(correo).rpartition("@")[2]


def es_institucional(correo: str) -> bool:
    """¿El dominio está en DOMINIOS_PERMITIDOS? Coincidencia exacta: 'utb.edu.co.malo.com' y
    'x.utb.edu.co' no cuentan. Sirve también para avisar a cuentas antiguas."""
    return dominio_de(correo) in config.DOMINIOS_PERMITIDOS


def error_correo_nuevo(correo: str) -> Optional[str]:
    """Regla ÚNICA para correos de registros y cambios de correo nuevos (ADR-0019).

    Devuelve el mensaje de error, o None si se admite. Espera el correo ya normalizado.
    """
    if not correo_valido(correo):
        return MSG_CORREO_INVALIDO
    usuario = correo.rpartition("@")[0]
    if (
        len(usuario) > _USUARIO_MAXIMO
        or any(c not in _CARACTERES_USUARIO for c in usuario)
        or usuario[0] in "._+-" or usuario[-1] == "." or ".." in usuario
    ):
        return MSG_CORREO_INVALIDO
    if not es_institucional(correo):
        return MSG_CORREO_NO_INSTITUCIONAL
    return None


def normalizar_nombre(nombre: str) -> str:
    """Quita espacios sobrantes (también los repetidos en medio)."""
    return " ".join((nombre or "").split())


def error_password(
    password: str, correo: Optional[str] = None, nombre: Optional[str] = None
) -> Optional[str]:
    """Devuelve el mensaje de error de la política, o None si la contraseña es válida."""
    if len(password or "") < PASSWORD_MINIMO:
        return MSG_CLAVE_CORTA
    p = password.strip().lower()
    if correo:
        c = normalizar_correo(correo)
        if p in (c, c.split("@")[0]):
            return MSG_CLAVE_IGUAL_CORREO
    if nombre and p == normalizar_nombre(nombre).lower():
        return MSG_CLAVE_IGUAL_NOMBRE
    return None
