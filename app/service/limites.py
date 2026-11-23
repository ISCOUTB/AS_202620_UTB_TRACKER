"""
Límites de frecuencia guardados en la base de datos (ADR-0014).

Ventana deslizante: cuenta los intentos con la misma clave en los últimos N segundos. Antes era
un diccionario en memoria: se vaciaba al reiniciar la API y cada proceso tenía el suyo.
Las consultas viven en `repository/limite_repository.py`; aquí solo está la regla (429).
"""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.repository import limite_repository as repo


def contar(db: Session, clave: str, ventana_segundos: int) -> int:
    return repo.contar(db, clave, ventana_segundos)


def anotar(db: Session, clave: str) -> None:
    """Agrega el intento a la sesión (el commit lo hace quien llama)."""
    repo.anotar(db, clave)


def limpiar(db: Session, clave: str) -> None:
    repo.limpiar(db, clave)


def exigir(db: Session, clave: str, maximo: int, ventana_segundos: int, mensaje: str) -> None:
    """429 si ya se alcanzó el máximo; si no, no hace nada (anotar es aparte)."""
    if contar(db, clave, ventana_segundos) >= maximo:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=mensaje)


def purgar_viejos(db: Session, dias: int = 2) -> int:
    """Borra intentos viejos (lo llama el worker de vez en cuando)."""
    return repo.purgar_viejos(db, dias)
