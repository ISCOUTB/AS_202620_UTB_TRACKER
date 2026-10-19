"""
Capa de servicio para el módulo de Recursos (S9 — req. 9.6).

Corrección de erosión arquitectónica: las consultas de base de datos se extraen
del router a esta capa de servicio, alineando el módulo 'resources' con el patrón
que ya usaba 'auth' (services/auth.py). El router pasa a ser solo enrutamiento HTTP;
la lógica de negocio y acceso a datos vive aquí.
"""
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import recurso_models
from app.schemas import schemas


def crear_recurso(db: Session, datos: schemas.RecursoCreate) -> recurso_models.Recurso:
    """Crea un recurso nuevo. Rechaza con 409 si el serial ya existe."""
    existente = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.serial == datos.serial
    ).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya existe un recurso con ese serial")

    nuevo = recurso_models.Recurso(**datos.model_dump(), estado="disponible")
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_recursos(db: Session) -> list[recurso_models.Recurso]:
    """Devuelve todos los recursos del catálogo."""
    return db.query(recurso_models.Recurso).all()


def obtener_recurso(db: Session, recurso_id: int) -> recurso_models.Recurso:
    """Busca un recurso por ID. Lanza 404 si no existe."""
    recurso = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.id == recurso_id
    ).first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")
    return recurso
