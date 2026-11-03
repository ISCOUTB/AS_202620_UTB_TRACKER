"""
Capa de servicio para la gestión de préstamos de recursos (S9 / S11).

Resiliencia y Concurrencia (S11):
- Req. 11.3 (Idempotencia): Gestión de 'X-Idempotency-Key' para prevenir duplicados.
- Riesgo R-02 / QS-06 (Prevención de condiciones de carrera): Bloqueo pesimista
  mediante '.with_for_update()' para control de concurrencia.
"""
from datetime import datetime, timezone
import json
from typing import Optional
import uuid

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.resilience import with_retry
from app.messaging.models import MensajeOutbox
from app.messaging.publisher import publicar_evento
from app.models.auth_models import Usuario
from app.models import recurso_models
from app.schemas import schemas


def _verificar_idempotencia(
    db: Session, idempotency_key: str | None
) -> recurso_models.Prestamo | None:
    """Verifica si ya existe un préstamo creado para la clave de idempotencia dada."""
    if not idempotency_key:
        return None
    registro = (
        db.query(recurso_models.IdempotenciaRegistro)
        .filter(recurso_models.IdempotenciaRegistro.clave == idempotency_key)
        .first()
    )
    return registro.prestamo if registro and registro.prestamo else None


def _obtener_recurso_con_bloqueo(db: Session, recurso_id: int) -> recurso_models.Recurso:
    """Obtiene el recurso aplicando bloqueo pesimista en motores compatibles (PostgreSQL)."""
    query = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.id == recurso_id
    )
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
    return recurso


def _resolver_correlation_id(correlation_id: str | None) -> str:
    """Resuelve el correlation_id desde argumento, contexto HTTP o genera un fallback."""
    if correlation_id and correlation_id != "system":
        return correlation_id
    try:
        from app.main import request_id_ctx
        cid = request_id_ctx.get()
        if cid and cid != "system":
            return cid
    except Exception:
        pass
    return str(uuid.uuid4())[:8]


def crear_prestamo(
    db: Session,
    datos: schemas.PrestamoCreate,
    idempotency_key: str | None = None,
    correlation_id: str | None = None,
) -> recurso_models.Prestamo:
    """
    Crea un préstamo aplicando:
    1. Idempotencia (S11 req. 11.3): si la clave ya existe, retorna el préstamo previo.
    2. Validación de usuario existente.
    3. Bloqueo pesimista (S11 req. 11.1 / R-02): bloqueo de fila con for_update en PostgreSQL.
    4. Regla central (QS-06): solo se presta si está disponible; cambia a 'prestado'.
    """
    prestamo_previo = _verificar_idempotencia(db, idempotency_key)
    if prestamo_previo:
        return prestamo_previo

    usuario = db.query(Usuario).filter(Usuario.id == datos.usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    recurso = _obtener_recurso_con_bloqueo(db, datos.recurso_id)

    nuevo = recurso_models.Prestamo(**datos.model_dump(), estado="activo")
    recurso.estado = "prestado"
    db.add(nuevo)

    if idempotency_key:
        db.add(
            recurso_models.IdempotenciaRegistro(
                clave=idempotency_key,
                endpoint="/prestamos",
                prestamo=nuevo,
            )
        )

    db.flush()

    cid = _resolver_correlation_id(correlation_id)
    ahora_utc = datetime.now(timezone.utc)
    fecha_esperada = (
        nuevo.fecha_devolucion_esperada.isoformat()
        if nuevo.fecha_devolucion_esperada
        else None
    )
    payload_evento = {
        "prestamo_id": nuevo.id,
        "usuario_id": nuevo.usuario_id,
        "recurso_id": nuevo.recurso_id,
        "fecha_devolucion_esperada": fecha_esperada,
    }

    publicar_evento(db, "prestamo.creado", payload_evento, cid)

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

    publicar_evento(
        db,
        "prestamo.devuelto",
        {
            "prestamo_id": prestamo.id,
            "usuario_id": prestamo.usuario_id,
            "recurso_id": prestamo.recurso_id,
            "fecha_devolucion_real": prestamo.fecha_devolucion_real.isoformat(),
        },
    )
    db.commit()
    db.refresh(prestamo)
    return prestamo


def marcar_prestamos_vencidos(
    db: Session, ahora: datetime | None = None
) -> list[recurso_models.Prestamo]:
    """Marca como vencidos los préstamos activos cuya fecha ya expiró."""
    ahora = ahora or datetime.now(timezone.utc)
    limite = ahora.replace(tzinfo=None) if ahora.tzinfo else ahora
    prestamos = db.query(recurso_models.Prestamo).filter(
        recurso_models.Prestamo.estado == "activo",
        recurso_models.Prestamo.fecha_devolucion_esperada < limite,
    ).all()
    for prestamo in prestamos:
        prestamo.estado = "vencido"
    if prestamos:
        db.commit()
        for prestamo in prestamos:
            db.refresh(prestamo)
    return prestamos
