"""
Modulo de dominio: prestamos.

Corte vertical S4: implementa la regla de negocio central del sistema
(documento de idea, seccion 6): "un recurso solo puede prestarse si su
estado es disponible". Al crear un prestamo exitoso, el recurso pasa a
estado "prestado" - este es el escenario QS-06 (confiabilidad de los
datos, arc42 seccion 10) hecho codigo.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter()


@router.post("", response_model=schemas.PrestamoOut, status_code=201)
def crear_prestamo(prestamo: schemas.PrestamoCreate, db: Session = Depends(get_db)):
    recurso = db.query(models.Recurso).filter(models.Recurso.id == prestamo.recurso_id).first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")

    if recurso.estado != "disponible":
        raise HTTPException(
            status_code=409,
            detail=f"El recurso no esta disponible (estado actual: {recurso.estado})",
        )

    nuevo = models.Prestamo(**prestamo.model_dump())
    recurso.estado = "prestado"
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@router.get("", response_model=list[schemas.PrestamoOut])
def listar_prestamos(db: Session = Depends(get_db)):
    return db.query(models.Prestamo).all()
