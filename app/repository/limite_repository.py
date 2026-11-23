"""Acceso a datos de los límites de frecuencia (tabla `intentos_limitados`, ADR-0014)."""
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.seguridad_models import IntentoLimitado


def ahora() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def contar(db: Session, clave: str, ventana_segundos: int) -> int:
    desde = ahora() - timedelta(seconds=ventana_segundos)
    return (
        db.query(IntentoLimitado)
        .filter(IntentoLimitado.clave == clave, IntentoLimitado.creado_en > desde)
        .count()
    )


def anotar(db: Session, clave: str) -> None:
    """Agrega el intento a la sesión (el commit lo hace quien llama)."""
    db.add(IntentoLimitado(clave=clave[:255], creado_en=ahora()))


def limpiar(db: Session, clave: str) -> None:
    db.query(IntentoLimitado).filter(IntentoLimitado.clave == clave).delete(
        synchronize_session=False
    )


def purgar_viejos(db: Session, dias: int = 2) -> int:
    corte = ahora() - timedelta(days=dias)
    return db.query(IntentoLimitado).filter(IntentoLimitado.creado_en < corte).delete(
        synchronize_session=False
    )
