"""
Capa de servicio para préstamos de salón.

Gestiona solicitudes de préstamo de salones validando conflictos
con horarios académicos y otros préstamos existentes.
"""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.auth_models import Usuario
from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.schemas.prestamos_salon import PrestamoSalonCreate


def _validar_salon(db: Session, salon_id: int) -> Salon:
    salon = db.query(Salon).filter(Salon.id == salon_id, Salon.activo.is_(True)).first()
    if not salon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Salón no encontrado")
    return salon


def _validar_usuario(db: Session, usuario_id: int) -> Usuario:
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return usuario


def _detectar_conflicto_horario(db: Session, salon_id: int, fecha_inicio, fecha_fin):
    """Verifica que la franja solicitada no choque con horarios académicos fijos."""
    dia_semana = fecha_inicio.isoweekday()  # 1=Lunes ... 7=Domingo
    hora_inicio = fecha_inicio.time()
    hora_fin = fecha_fin.time()

    conflicto = db.query(Horario).filter(
        Horario.salon_id == salon_id,
        Horario.dia_semana == dia_semana,
        Horario.activo.is_(True),
        Horario.hora_inicio < hora_fin,
        Horario.hora_fin > hora_inicio,
    ).first()

    if conflicto:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Conflicto con horario académico: {conflicto.materia or 'clase'} "
                   f"({conflicto.hora_inicio}-{conflicto.hora_fin}, {conflicto.profesor or 'sin profesor'})",
        )


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


def actualizar_estado_prestamo_salon(db: Session, prestamo_id: int, nuevo_estado: str) -> PrestamoSalon:
    """Actualiza el estado de un préstamo de salón (aprobar, rechazar, cancelar, etc.)."""
    TRANSICIONES_VALIDAS = {
        "pendiente": ["aprobado", "rechazado", "cancelado"],
        "aprobado": ["en_uso", "cancelado"],
        "en_uso": ["finalizado"],
    }

    prestamo = db.query(PrestamoSalon).filter(PrestamoSalon.id == prestamo_id).first()
    if not prestamo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Préstamo de salón no encontrado")

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
