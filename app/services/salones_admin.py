"""
Capa de servicio de la administración de salones.

Reglas:
- "Quién tiene el salón" cruza el horario académico vigente (hora de Colombia)
  con los préstamos de salón aprobados/en uso (guardados en UTC sin zona).
- La presencia del profesor solo se puede registrar mientras hay una clase en curso.
- Los reportes los puede crear cualquier usuario autenticado; solo el auxiliar los resuelve.
"""
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.salon_models import (
    Horario,
    PrestamoSalon,
    PresenciaSalon,
    ReporteSalon,
    Salon,
)
from app.schemas.enums import EstadoReporteSalon
from app.schemas.salones_admin import PresenciaUpdate, ReporteSalonCreate
from app.services import auditoria, equipamiento, estado_salon
from app.services.salones import obtener_salon

# Hora del campus y conversión a UTC: una sola definición (ADR-0022, estado_salon).
_ahora_campus = estado_salon.ahora_campus
_a_utc_naive = estado_salon.a_utc_naive


def _clase_en_curso(db: Session, salon_id: int, local: datetime) -> Optional[Horario]:
    return estado_salon.clases_en_curso(db, [salon_id], local).get(salon_id)


def _presencia(db: Session, horario_id: int, fecha: date) -> Optional[PresenciaSalon]:
    return (
        db.query(PresenciaSalon)
        .filter(PresenciaSalon.horario_id == horario_id, PresenciaSalon.fecha == fecha)
        .first()
    )


def _conteos(db: Session, modelo, estado: str, ids: list[int]) -> dict[int, int]:
    """{salon_id: cuántas filas con ese estado} en UNA consulta agrupada."""
    if not ids:
        return {}
    filas = (
        db.query(modelo.salon_id, func.count(modelo.id))
        .filter(modelo.salon_id.in_(ids), modelo.estado == estado)
        .group_by(modelo.salon_id)
        .all()
    )
    return {salon_id: int(n) for salon_id, n in filas}


def _info_clase(clase: Optional[Horario]) -> Optional[dict]:
    if not clase:
        return None
    return {
        "horario_id": clase.id,
        "materia": clase.materia,
        "profesor": clase.profesor,
        "hora_inicio": clase.hora_inicio,
        "hora_fin": clase.hora_fin,
    }


def _info_prestamo(prestamo: Optional[PrestamoSalon]) -> Optional[dict]:
    if not prestamo:
        return None
    nombre_u = prestamo.usuario.nombre if prestamo.usuario else f"Usuario #{prestamo.usuario_id}"
    return {
        "prestamo_id": prestamo.id,
        "usuario_id": prestamo.usuario_id,
        "usuario_nombre": nombre_u,
        "estado": prestamo.estado,
        "fecha_inicio": prestamo.fecha_inicio,
        "fecha_fin": prestamo.fecha_fin,
        "motivo": prestamo.motivo,
    }


def _armar_ocupacion_salon(
    salon: Salon,
    clase: Optional[Horario],
    prestamo: Optional[PrestamoSalon],
    presencias: dict[int, PresenciaSalon],
    pendientes: dict[int, int],
    abiertos: dict[int, int],
) -> dict:
    if clase:
        ocupante = "clase"
    elif prestamo:
        ocupante = "prestamo"
    else:
        ocupante = "libre"
    registro = presencias.get(clase.id) if clase else None
    return {
        "salon": salon,
        "ocupante": ocupante,
        "clase_actual": _info_clase(clase),
        "prestamo_actual": _info_prestamo(prestamo),
        "profesor_presente": registro.profesor_presente if registro else None,
        "solicitudes_pendientes": pendientes.get(salon.id, 0),
        "reportes_abiertos": abiertos.get(salon.id, 0),
    }


def _ocupaciones(db: Session, salones: list[Salon], local: datetime) -> list[dict]:
    """Foto en vivo de muchos salones con un número FIJO de consultas (sin N+1)."""
    ids = [s.id for s in salones]
    clases = estado_salon.clases_en_curso(db, ids, local)
    solicitudes = estado_salon.solicitudes_en_curso(db, ids, _a_utc_naive(local))
    horarios = [c.id for c in clases.values()]
    presencias = {
        p.horario_id: p for p in db.query(PresenciaSalon).filter(
            PresenciaSalon.horario_id.in_(horarios), PresenciaSalon.fecha == local.date()
        ).all()
    } if horarios else {}
    pendientes = _conteos(db, PrestamoSalon, "pendiente", ids)
    abiertos = _conteos(db, ReporteSalon, "abierto", ids)

    return [
        _armar_ocupacion_salon(
            salon,
            clases.get(salon.id),
            solicitudes.get(salon.id),
            presencias,
            pendientes,
            abiertos,
        )
        for salon in salones
    ]


def listar_ocupacion(db: Session, momento: Optional[datetime] = None) -> list[dict]:
    local = _ahora_campus(momento)
    salones = db.query(Salon).filter(Salon.activo.is_(True)).order_by(Salon.nombre).all()
    # Tipo, equipamiento y estado calculado (ADR-0017/0022): consultas agrupadas para todos.
    equipamiento.adjuntar(db, salones, momento)
    return _ocupaciones(db, salones, local)


def obtener_ocupacion(db: Session, salon_id: int, momento: Optional[datetime] = None) -> dict:
    salon = equipamiento.adjuntar(db, [obtener_salon(db, salon_id)], momento)[0]
    return _ocupaciones(db, [salon], _ahora_campus(momento))[0]


def registrar_presencia(
    db: Session,
    salon_id: int,
    datos: PresenciaUpdate,
    auxiliar_id: int,
    momento: Optional[datetime] = None,
) -> PresenciaSalon:
    obtener_salon(db, salon_id)
    local = _ahora_campus(momento)
    clase = _clase_en_curso(db, salon_id, local)
    if clase is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No hay una clase en curso en este salón",
        )

    registro = _presencia(db, clase.id, local.date())
    if registro is None:
        registro = PresenciaSalon(
            salon_id=salon_id,
            horario_id=clase.id,
            fecha=local.date(),
            profesor_presente=datos.profesor_presente,
            nota=datos.nota,
            registrado_por=auxiliar_id,
        )
        db.add(registro)
    else:
        registro.profesor_presente = datos.profesor_presente
        registro.nota = datos.nota
        registro.registrado_por = auxiliar_id
    auditoria.registrar(
        db, "salon.presencia", "salon", salon_id, actor_id=auxiliar_id,
        detalle={"horario_id": clase.id, "profesor": clase.profesor,
                 "profesor_presente": datos.profesor_presente, "nota": datos.nota},
    )
    db.commit()
    db.refresh(registro)
    return registro


def crear_reporte(
    db: Session, salon_id: int, datos: ReporteSalonCreate, usuario_id: int
) -> ReporteSalon:
    obtener_salon(db, salon_id)
    reporte = ReporteSalon(
        salon_id=salon_id,
        usuario_id=usuario_id,
        tipo=datos.tipo.value,
        descripcion=datos.descripcion.strip(),
    )
    db.add(reporte)
    db.flush()
    auditoria.registrar(
        db, "salon.reporte.crear", "reporte_salon", reporte.id, actor_id=usuario_id,
        detalle={"salon_id": salon_id, "tipo": reporte.tipo},
    )
    db.commit()
    db.refresh(reporte)
    return reporte


def listar_todos_los_reportes(db: Session, estado: Optional[str] = None) -> list[ReporteSalon]:
    """Reportes de todos los salones, los más recientes primero (pantalla Control del auxiliar)."""
    query = db.query(ReporteSalon)
    if estado:
        query = query.filter(ReporteSalon.estado == estado)
    return query.order_by(ReporteSalon.created_at.desc()).all()


def listar_reportes(
    db: Session, salon_id: int, estado: Optional[str] = None
) -> list[ReporteSalon]:
    obtener_salon(db, salon_id)
    query = db.query(ReporteSalon).filter(ReporteSalon.salon_id == salon_id)
    if estado:
        query = query.filter(ReporteSalon.estado == estado)
    return query.order_by(ReporteSalon.created_at.desc()).all()


def actualizar_estado_reporte(
    db: Session, salon_id: int, reporte_id: int, nuevo_estado: EstadoReporteSalon,
    actor_id: Optional[int] = None,
) -> ReporteSalon:
    reporte = (
        db.query(ReporteSalon)
        .filter(ReporteSalon.id == reporte_id, ReporteSalon.salon_id == salon_id)
        .first()
    )
    if reporte is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Reporte no encontrado"
        )
    anterior = reporte.estado
    reporte.estado = nuevo_estado.value
    reporte.resuelto_en = (
        datetime.now(timezone.utc).replace(tzinfo=None)
        if nuevo_estado == EstadoReporteSalon.RESUELTO
        else None
    )
    auditoria.registrar(
        db, "salon.reporte.estado", "reporte_salon", reporte.id, actor_id=actor_id,
        detalle={"salon_id": salon_id, "de": anterior, "a": reporte.estado},
    )
    db.commit()
    db.refresh(reporte)
    return reporte
