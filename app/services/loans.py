"""
Capa de servicio para el módulo de Préstamos (S9 / S11).

Resiliencia y Concurrencia (S11):
- Req. 11.3 (Idempotencia): Si se recibe 'idempotency_key', se verifica si ya fue procesada.
  De ser así, retorna el préstamo original sin crear duplicados ni generar error 409.
- Riesgo R-02 / QS-06 (Prevención de Race Conditions): Bloqueo pesimista de fila
  mediante '.with_for_update()' para evitar que dos peticiones simultáneas lean
  el recurso como 'disponible' en el mismo milisegundo.
"""
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import recurso_models
from app.schemas import schemas


def crear_prestamo(
    db: Session,
    datos: schemas.PrestamoCreate,
    idempotency_key: str | None = None,
) -> recurso_models.Prestamo:
    """
    Crea un préstamo aplicando:
    1. Idempotencia (S11 req. 11.3): si la clave ya existe, retorna el préstamo previo.
    2. Bloqueo pesimista (S11 req. 11.1 / R-02): bloqueo de fila con for_update en PostgreSQL.
    3. Regla central (QS-06): solo se presta si está disponible; cambia a 'prestado'.
    """
    # 1. Comprobación de idempotencia
    if idempotency_key:
        registro_previo = db.query(recurso_models.IdempotenciaRegistro).filter(
            recurso_models.IdempotenciaRegistro.clave == idempotency_key
        ).first()
        if registro_previo and registro_previo.prestamo:
            return registro_previo.prestamo

    # 2. Bloqueo pesimista de fila para evitar condiciones de carrera (QS-06)
    query = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.id == datos.recurso_id
    )
    # with_for_update solo se aplica si la base de datos es compatible (PostgreSQL)
    try:
        bind = db.get_bind()
        if bind and not bind.name.startswith("sqlite"):
            query = query.with_for_update()
    except Exception:
        pass

    recurso = query.first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")

    if recurso.estado != "disponible":
        raise HTTPException(
            status_code=409,
            detail=f"El recurso no esta disponible (estado actual: {recurso.estado})",
        )

    # 3. Transacción atómica ACID local
    nuevo = recurso_models.Prestamo(**datos.model_dump())
    recurso.estado = "prestado"
    db.add(nuevo)

    if idempotency_key:
        registro_idem = recurso_models.IdempotenciaRegistro(
            clave=idempotency_key,
            endpoint="/prestamos",
            prestamo=nuevo,
        )
        db.add(registro_idem)

    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_prestamos(db: Session) -> list[recurso_models.Prestamo]:
    """Devuelve todos los préstamos registrados."""
    return db.query(recurso_models.Prestamo).all()
