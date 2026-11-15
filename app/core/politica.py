"""
Reglas de identidad compartidas por schemas y servicios (ADR-0014).

La app Flutter repite exactamente estas reglas y mensajes en
`frontend/lib/core/utils/politica.dart`: si cambias una, cambia la otra.
"""
import re
from typing import Optional

PASSWORD_MINIMO = 8

MSG_PASSWORD_CORTA = f"La contraseña debe tener al menos {PASSWORD_MINIMO} caracteres"
MSG_PASSWORD_IGUAL_CORREO = "La contraseña no puede ser igual a tu correo"
MSG_PASSWORD_IGUAL_NOMBRE = "La contraseña no puede ser igual a tu nombre de usuario"
MSG_CORREO_INVALIDO = "Escribe un correo válido"

_CORREO = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def normalizar_correo(correo: str) -> str:
    """Minúsculas y sin espacios: 'Ana@UTB.edu.co ' y 'ana@utb.edu.co' son la misma cuenta."""
    return (correo or "").strip().lower()


def correo_valido(correo: str) -> bool:
    # Sin saltos de línea ni comas: evita inyección de cabeceras en el correo saliente.
    return bool(_CORREO.match(correo)) and not any(c in correo for c in "\r\n,;<>\"")


def normalizar_nombre(nombre: str) -> str:
    """Quita espacios sobrantes (también los repetidos en medio)."""
    return " ".join((nombre or "").split())


def error_password(
    password: str, correo: Optional[str] = None, nombre: Optional[str] = None
) -> Optional[str]:
    """Devuelve el mensaje de error de la política, o None si la contraseña es válida."""
    if len(password or "") < PASSWORD_MINIMO:
        return MSG_PASSWORD_CORTA
    p = password.strip().lower()
    if correo:
        c = normalizar_correo(correo)
        if p in (c, c.split("@")[0]):
            return MSG_PASSWORD_IGUAL_CORREO
    if nombre and p == normalizar_nombre(nombre).lower():
        return MSG_PASSWORD_IGUAL_NOMBRE
    return None
