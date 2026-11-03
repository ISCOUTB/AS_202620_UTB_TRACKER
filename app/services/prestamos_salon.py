"""
Capa de servicio para préstamos de salón.

Gestiona solicitudes de préstamo de salones validando conflictos
con horarios académicos y otros préstamos existentes.
"""
from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.schemas.prestamos_salon import PrestamoSalonCreate

MSG_PRESTAMO_NO_ENCONTRADO = "Préstamo de salón no encontrado"


def _validar_salon(db: Session, salon_id: int) -> Salon:
    salon = db.query(Salon).filter(Salon.id == salon_id, Salon.activo.is_(True)).first()
    if not salon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Salón no encontrado")
    return salon


def _detectar_conflicto_horario(db: Session, salon_id: int, fecha_inicio, fecha_fin):
    """
    Verifica que la franja solicitada no choque con horarios académicos fijos.

    Soporta préstamos que abarcan medianoche: itera cada día cubierto por
    la franja (fecha_inicio.date … fecha_fin.date inclusive) y valida las
    horas que correspondan a ese día.
    """
    from datetime import date, time as dtime, timedelta

    dia_actual = fecha_inicio.date()
    dia_fin = fecha_fin.date()

    while dia_actual <= dia_fin:
        dia_semana = dia_actual.isoweekday()  # 1=Lunes … 7=Domingo

        hora_inicio_check = fecha_inicio.time() if dia_actual == fecha_inicio.date() else dtime(0, 0)
        hora_fin_check = fecha_fin.time() if dia_actual == fecha_fin.date() else dtime(23, 59)

        conflicto = db.query(Horario).filter(
            Horario.salon_id == salon_id,
            Horario.dia_semana == dia_semana,
            Horario.activo.is_(True),
            Horario.hora_inicio < hora_fin_check,
            Horario.hora_fin > hora_inicio_check,
        ).first()

        if conflicto:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Conflicto con horario académico: {conflicto.materia or 'clase'} "
                       f"({conflicto.hora_inicio}-{conflicto.hora_fin}, {conflicto.profesor or 'sin profesor'})",
            )

        dia_actual += timedelta(days=1)


def _detectar_conflicto_prestamo(db: Session, salon_id: int, fecha_inicio, fecha_fin, excluir_id: int | None = None):
    """Verifica que no exista otro préstamo de salón aprobado/en_uso que se cruce."""
    query = db.query(PrestamoSalon).filter(
        PrestamoSalon.salon_id == salon_id,
        PrestamoSalon.estado.in_(["pendiente", "aprobado", "en_uso"]),
        PrestamoSalon.fecha_inicio < fecha_fin,
        PrestamoSalon.fecha_fin > fecha_inicio,
    )
    if excluir_id:
        query = query.filter(PrestamoSalon.id != excluir_id)
    conflicto = query.first()
    if conflicto:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ya existe un préstamo de salón en esa franja (ID: {conflicto.id}, estado: {conflicto.estado})",
        )


def crear_prestamo_salon(db: Session, datos: PrestamoSalonCreate, usuario_id: int) -> PrestamoSalon:
    """
    Crea una solicitud de préstamo de salón.
    Valida que no haya conflictos con horarios académicos ni con otros préstamos.
    """
    _validar_salon(db, datos.salon_id)
    _detectar_conflicto_horario(db, datos.salon_id, datos.fecha_inicio, datos.fecha_fin)
    _detectar_conflicto_prestamo(db, datos.salon_id, datos.fecha_inicio, datos.fecha_fin)

    nuevo = PrestamoSalon(
        salon_id=datos.salon_id,
        usuario_id=usuario_id,
        fecha_inicio=datos.fecha_inicio,
        fecha_fin=datos.fecha_fin,
        motivo=datos.motivo,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_prestamos_salon(
    db: Session,
    salon_id: int | None = None,
    estado: str | None = None,
    usuario_id: int | None = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[PrestamoSalon], int]:
    """Lista préstamos de salón con filtros opcionales y paginación."""
    query = db.query(PrestamoSalon)
    if salon_id is not None:
        query = query.filter(PrestamoSalon.salon_id == salon_id)
    if estado:
        query = query.filter(PrestamoSalon.estado == estado)
    if usuario_id is not None:
        query = query.filter(PrestamoSalon.usuario_id == usuario_id)
    total = query.count()
    items = query.order_by(PrestamoSalon.created_at.desc()).offset(skip).limit(limit).all()
    return items, total


def obtener_prestamo_salon(
    db: Session, prestamo_id: int, usuario_id: int | None = None
) -> PrestamoSalon:
    """
    Obtiene un préstamo de salón por ID.
    Si se pasa usuario_id, verifica que el préstamo le pertenezca (usuarios normales).
    """
    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)
    if usuario_id is not None and prestamo.usuario_id != usuario_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para consultar este préstamo",
        )
    return prestamo


def actualizar_estado_prestamo_salon(db: Session, prestamo_id: int, nuevo_estado: str) -> PrestamoSalon:
    """Actualiza el estado de un préstamo de salón (aprobar, rechazar, cancelar, etc.)."""
    TRANSICIONES_VALIDAS = {
        "pendiente": ["aprobado", "rechazado", "cancelado"],
        "aprobado": ["en_uso", "cancelado"],
        "en_uso": ["finalizado"],
    }

    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)

    estados_permitidos = TRANSICIONES_VALIDAS.get(prestamo.estado, [])
    if nuevo_estado not in estados_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transición no válida: {prestamo.estado} → {nuevo_estado}. "
                   f"Estados permitidos: {estados_permitidos}",
        )

    prestamo.estado = nuevo_estado
    db.commit()
    db.refresh(prestamo)
    return prestamo


def cancelar_prestamo_propio(db: Session, prestamo_id: int, usuario_id: int) -> PrestamoSalon:
    """
    Permite al propietario del préstamo cancelarlo si aún está en estado pendiente.
    Lanza 403 si el préstamo pertenece a otro usuario, 409 si ya no es cancelable.
    """
    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_PRESTAMO_NO_ENCONTRADO)
    if prestamo.usuario_id != usuario_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para cancelar este préstamo",
        )
    if prestamo.estado != "pendiente":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Solo puedes cancelar préstamos en estado 'pendiente'. Estado actual: {prestamo.estado}",
        )
    prestamo.estado = "cancelado"
    db.commit()
    db.refresh(prestamo)
    return prestamo


def expirar_prestamos_pendientes(db: Session) -> int:
    """
    Marca como 'cancelado' todos los préstamos pendientes cuya fecha_inicio
    ya pasó (TTL de solicitudes sin respuesta).
    Devuelve el número de registros afectados.
    """
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)  # naïve UTC
    pendientes_vencidos = db.query(PrestamoSalon).filter(
        PrestamoSalon.estado == "pendiente",
        PrestamoSalon.fecha_inicio < ahora,
    ).all()

    for p in pendientes_vencidos:
        p.estado = "cancelado"

    db.commit()
    return len(pendientes_vencidos)
