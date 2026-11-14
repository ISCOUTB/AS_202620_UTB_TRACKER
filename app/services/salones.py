"""
Capa de servicio para el módulo de Salones.

CRUD completo de salones con soft-delete, consulta de disponibilidad
cruzando horarios académicos y préstamos existentes.
"""
from datetime import date, datetime, time
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.schemas.salones import SalonCreate, SalonUpdate
from app.services import auditoria


def crear_salon(db: Session, datos: SalonCreate, actor_id: Optional[int] = None) -> Salon:
    """Crea un salón nuevo. Rechaza con 409 si el nombre ya existe."""
    existente = db.query(Salon).filter(Salon.nombre == datos.nombre).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un salón con ese nombre",
        )
    nuevo = Salon(**datos.model_dump())
    db.add(nuevo)
    db.flush()
    auditoria.registrar(
        db, "salon.crear", "salon", nuevo.id, actor_id=actor_id,
        detalle={"nombre": nuevo.nombre, "capacidad": nuevo.capacidad},
    )
    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_salones(
    db: Session,
    skip: int = 0,
    limit: int = 50,
    estado: Optional[str] = None,
    edificio: Optional[str] = None,
    busqueda: Optional[str] = None,
) -> tuple[list[Salon], int]:
    """Devuelve salones activos con filtros opcionales y paginación."""
    query = db.query(Salon).filter(Salon.activo.is_(True))
    if estado:
        query = query.filter(Salon.estado == estado)
    if edificio:
        query = query.filter(Salon.edificio == edificio)
    if busqueda:
        query = query.filter(Salon.nombre.ilike(f"%{busqueda}%"))
    total = query.count()
    items = query.offset(skip).limit(limit).all()
    return items, total


def obtener_salon(db: Session, salon_id: int) -> Salon:
    """Busca un salón por ID. Lanza 404 si no existe o está inactivo."""
    salon = db.query(Salon).filter(
        Salon.id == salon_id, Salon.activo.is_(True)
    ).first()
    if not salon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Salón no encontrado"
        )
    return salon


def actualizar_salon(
    db: Session, salon_id: int, datos: SalonUpdate, actor_id: Optional[int] = None
) -> Salon:
    """Actualiza un salón existente. Solo modifica campos proporcionados."""
    salon = obtener_salon(db, salon_id)
    update_data = datos.model_dump(exclude_unset=True)
    cambios = {
        campo: {"de": getattr(salon, campo), "a": valor}
        for campo, valor in update_data.items() if getattr(salon, campo) != valor
    }
    for campo, valor in update_data.items():
        setattr(salon, campo, valor)
    if cambios:
        auditoria.registrar(
            db, "salon.actualizar", "salon", salon.id, actor_id=actor_id, detalle=cambios
        )
    db.commit()
    db.refresh(salon)
    return salon


def eliminar_salon(db: Session, salon_id: int, actor_id: Optional[int] = None) -> dict:
    """Soft-delete: marca el salón como inactivo."""
    salon = obtener_salon(db, salon_id)
    salon.activo = False
    auditoria.registrar(
        db, "salon.eliminar", "salon", salon.id, actor_id=actor_id, detalle={"nombre": salon.nombre}
    )
    db.commit()
    return {"message": "Salón eliminado correctamente"}


def obtener_disponibilidad(
    db: Session,
    salon_id: int,
    dia_semana: int,
    fecha: Optional[date] = None,
) -> list[dict]:
    """
    Calcula las franjas horarias disponibles para un salón en un día específico.
    Cruza los horarios académicos fijos con los préstamos de salón existentes
    para determinar qué horas están libres.
    """
    obtener_salon(db, salon_id)

    # Obtener horarios académicos ocupados para ese día
    horarios_ocupados = (
        db.query(Horario)
        .filter(
            Horario.salon_id == salon_id,
            Horario.dia_semana == dia_semana,
            Horario.activo.is_(True),
        )
        .order_by(Horario.hora_inicio)
        .all()
    )

    # Franja del día completo (6:00 AM a 10:00 PM)
    HORA_APERTURA = time(6, 0)
    HORA_CIERRE = time(22, 0)

    # Construir lista de bloques ocupados
    bloques_ocupados = [
        (h.hora_inicio, h.hora_fin) for h in horarios_ocupados
    ]

    # También considerar préstamos de salón aprobados/en_uso para esa fecha.
    # Se usan datetimes naïve (sin tzinfo) para ser consistentes con la BD,
    # que almacena fechas en UTC naïve y funciona tanto en SQLite como en PostgreSQL.
    if fecha:
        inicio_dia = datetime.combine(fecha, HORA_APERTURA)  # naïve, sin tzinfo
        fin_dia = datetime.combine(fecha, HORA_CIERRE)       # naïve, sin tzinfo

        prestamos_activos = (
            db.query(PrestamoSalon)
            .filter(
                PrestamoSalon.salon_id == salon_id,
                PrestamoSalon.estado.in_(["aprobado", "en_uso"]),
                PrestamoSalon.fecha_inicio < fin_dia,
                PrestamoSalon.fecha_fin > inicio_dia,
            )
            .all()
        )
        for p in prestamos_activos:
            bloques_ocupados.append((p.fecha_inicio.time(), p.fecha_fin.time()))

    # Ordenar bloques por hora de inicio
    bloques_ocupados.sort(key=lambda b: b[0])

    # Calcular franjas libres
    franjas_libres = []
    cursor = HORA_APERTURA

    for inicio, fin in bloques_ocupados:
        if cursor < inicio:
            franjas_libres.append({
                "dia_semana": dia_semana,
                "hora_inicio": cursor.isoformat(),
                "hora_fin": inicio.isoformat(),
            })
        if fin > cursor:
            cursor = fin

    if cursor < HORA_CIERRE:
        franjas_libres.append({
            "dia_semana": dia_semana,
            "hora_inicio": cursor.isoformat(),
            "hora_fin": HORA_CIERRE.isoformat(),
        })

    return franjas_libres
