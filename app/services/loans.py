"""
Capa de servicio para la gestión de préstamos de recursos (S9 / S11).

Resiliencia y Concurrencia (S11):
- Req. 11.3 (Idempotencia): Gestión de 'X-Idempotency-Key' para prevenir duplicados.
- Riesgo R-02 / QS-06 (Prevención de condiciones de carrera): Bloqueo pesimista
  mediante '.with_for_update()' para control de concurrencia.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.resilience import with_retry

from app.models.auth_models import Usuario
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
    2. Validación de usuario existente.
    3. Bloqueo pesimista (S11 req. 11.1 / R-02): bloqueo de fila con for_update en PostgreSQL.
    4. Regla central (QS-06): solo se presta si está disponible; cambia a 'prestado'.
    """
    # 1. Comprobación de idempotencia
    if idempotency_key:
        registro_previo = db.query(recurso_models.IdempotenciaRegistro).filter(
            recurso_models.IdempotenciaRegistro.clave == idempotency_key
        ).first()
        if registro_previo and registro_previo.prestamo:
            return registro_previo.prestamo

    # 2. Validar que el usuario exista
    usuario = db.query(Usuario).filter(Usuario.id == datos.usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # 3. Bloqueo pesimista de fila para evitar condiciones de carrera (QS-06)
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

    # 4. Transacción atómica ACID local
    nuevo = recurso_models.Prestamo(**datos.model_dump(), estado="activo")
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


def listar_prestamos(
    db: Session,
    usuario_id: Optional[int] = None,
    estado: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[recurso_models.Prestamo], int]:
    """Devuelve préstamos con filtros opcionales y paginación."""
    query = db.query(recurso_models.Prestamo)
    if usuario_id is not None:
        query = query.filter(recurso_models.Prestamo.usuario_id == usuario_id)
    if estado:
        query = query.filter(recurso_models.Prestamo.estado == estado)
    total = query.count()
    items = query.order_by(recurso_models.Prestamo.fecha_prestamo.desc()).offset(skip).limit(limit).all()
    return items, total


def devolver_prestamo(db: Session, prestamo_id: int) -> recurso_models.Prestamo:
    """
    Registra la devolución de un préstamo:
    1. Marca fecha_devolucion_real con la fecha actual.
    2. Cambia el estado del préstamo a 'devuelto'.
    3. Restaura el estado del recurso a 'disponible'.
    """
    prestamo = db.query(recurso_models.Prestamo).filter(
        recurso_models.Prestamo.id == prestamo_id
    ).first()
    if not prestamo:
        raise HTTPException(status_code=404, detail="Préstamo no encontrado")

    if prestamo.estado == "devuelto":
        raise HTTPException(status_code=409, detail="Este préstamo ya fue devuelto")

    if prestamo.estado not in ("activo", "vencido"):
        raise HTTPException(
            status_code=400,
            detail=f"No se puede devolver un préstamo con estado '{prestamo.estado}'",
        )

    # Marcar devolución
    prestamo.fecha_devolucion_real = datetime.now(timezone.utc)
    prestamo.estado = "devuelto"

    # Restaurar recurso a disponible
    recurso = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.id == prestamo.recurso_id
    ).first()
    if recurso:
        recurso.estado = "disponible"

    db.commit()
    db.refresh(prestamo)
    return prestamo
