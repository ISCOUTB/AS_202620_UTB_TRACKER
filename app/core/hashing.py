"""
Utilidades de hashing de contraseñas (S9 — req. 9.8).

Usa bcrypt nativo directamente, garantizando compatibilidad y eliminando
la dependencia de passlib (que presenta problemas con bcrypt >= 4.0).
Seguridad: las contraseñas NUNCA se almacenan en texto plano — ver ADR-0004
y el escenario QS-04 en arc42 sección 10.
"""
import bcrypt


def hash_password(plain_password: str) -> str:
    """Devuelve el hash bcrypt de una contraseña en texto plano."""
    password_bytes = plain_password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica que una contraseña en texto plano coincida con su hash almacenado."""
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8"),
        )
    except Exception:
        return False
