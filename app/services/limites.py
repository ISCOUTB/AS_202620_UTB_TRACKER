"""
Límites de frecuencia guardados en la base de datos (ADR-0014).

Ventana deslizante: cuenta los intentos con la misma clave en los últimos N segundos. Antes era
un diccionario en memoria: se vaciaba al reiniciar la API y cada proceso tenía el suyo.
"""
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.seguridad_models import IntentoLimitado


def _ahora() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def contar(db: Session, clave: str, ventana_segundos: int) -> int:
    desde = _ahora() - timedelta(seconds=ventana_segundos)
    return (
        db.query(IntentoLimitado)
        .filter(IntentoLimitado.clave == clave, IntentoLimitado.creado_en > desde)
        .count()
    )


def anotar(db: Session, clave: str) -> None:
    """Agrega el intento a la sesión (el commit lo hace quien llama)."""
    db.add(IntentoLimitado(clave=clave[:255], creado_en=_ahora()))


def limpiar(db: Session, clave: str) -> None:
    db.query(IntentoLimitado).filter(IntentoLimitado.clave == clave).delete(
        synchronize_session=False
    )


def exigir(db: Session, clave: str, maximo: int, ventana_segundos: int, mensaje: str) -> None:
    """429 si ya se alcanzó el máximo; si no, no hace nada (anotar es aparte)."""
    if contar(db, clave, ventana_segundos) >= maximo:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=mensaje)


def purgar_viejos(db: Session, dias: int = 2) -> int:
    """Borra intentos viejos (lo llama el worker de vez en cuando)."""
    corte = _ahora() - timedelta(days=dias)
    return db.query(IntentoLimitado).filter(IntentoLimitado.creado_en < corte).delete(
        synchronize_session=False
    )
