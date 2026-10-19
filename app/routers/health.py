from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import get_db

router = APIRouter(tags=["salud"])


@router.get("/salud")
def health_check(db: Annotated[Session, Depends(get_db)]):
    """
    Health check profundo: verifica conectividad real contra la base de datos (S8).
    Un check que solo devuelve 'ok' sin tocar la BD no detecta caídas del motor
    de persistencia — este endpoint ejecuta SELECT 1 para confirmar que el pool
    de conexiones está activo y PostgreSQL responde.
    """
    db.execute(text("SELECT 1"))
    return {
        "status": "ok",
        "proyecto": "UTB Tracker",
        "database": "connected",
    }
