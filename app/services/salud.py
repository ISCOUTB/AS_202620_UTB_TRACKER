"""Comprobación de la base para GET /salud (S8). El router no toca la base directamente."""
from sqlalchemy import text
from sqlalchemy.orm import Session


def base_responde(db: Session) -> None:
    """Lanza la excepción del motor si PostgreSQL/SQLite no responde a SELECT 1."""
    db.execute(text("SELECT 1"))
