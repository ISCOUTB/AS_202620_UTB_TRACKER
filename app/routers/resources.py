"""
Modulo de dominio: recursos.

Corte vertical S4: crear y listar recursos (equipos electronicos de
salones/laboratorios). Ver docs/aspectos.md, A-0X, y arc42 seccion 5.2.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter()


@router.post("", response_model=schemas.RecursoOut, status_code=201)
def crear_recurso(recurso: schemas.RecursoCreate, db: Session = Depends(get_db)):
    existente = db.query(models.Recurso).filter(models.Recurso.serial == recurso.serial).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya existe un recurso con ese serial")

    nuevo = models.Recurso(**recurso.model_dump(), estado="disponible")
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@router.get("", response_model=list[schemas.RecursoOut])
def listar_recursos(db: Session = Depends(get_db)):
    return db.query(models.Recurso).all()


@router.get("/{recurso_id}", response_model=schemas.RecursoOut)
def obtener_recurso(recurso_id: int, db: Session = Depends(get_db)):
    recurso = db.query(models.Recurso).filter(models.Recurso.id == recurso_id).first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")
    return recurso
