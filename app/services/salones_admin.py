"""
Capa de servicio de la administración de salones.

Reglas:
- "Quién tiene el salón" cruza el horario académico vigente (hora de Colombia)
  con los préstamos de salón aprobados/en uso (guardados en UTC sin zona).
- La presencia del profesor solo se puede registrar mientras hay una clase en curso.
- Los reportes los puede crear cualquier usuario autenticado; solo el auxiliar los resuelve.
"""
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.auth_models import Usuario
from app.models.salon_models import (
    Horario,
    PrestamoSalon,
    PresenciaSalon,
    ReporteSalon,
    Salon,
)
from app.schemas.enums import EstadoReporteSalon
from app.schemas.salones_admin import PresenciaUpdate, ReporteSalonCreate
from app.services.salones import obtener_salon

# Colombia no tiene horario de verano: un desfase fijo evita depender de tzdata.
ZONA_CAMPUS = timezone(timedelta(hours=-5))


def _ahora_campus(momento: Optional[datetime]) -> datetime:
    """Hora local del campus. `momento` (sin zona) permite simular otra hora."""
    if momento is not None:
        return momento.replace(tzinfo=None)
    return datetime.now(ZONA_CAMPUS).replace(tzinfo=None)


def _a_utc_naive(local: datetime) -> datetime:
    """Convierte una hora local del campus a UTC sin zona (como guarda el backend)."""
    return local - timedelta(hours=-5)


def _clase_en_curso(db: Session, salon_id: int, local: datetime) -> Optional[Horario]:
    return (
        db.query(Horario)
        .filter(
            Horario.salon_id == salon_id,
            Horario.activo.is_(True),
            Horario.dia_semana == local.isoweekday(),
            Horario.hora_inicio <= local.time(),
            Horario.hora_fin > local.time(),
        )
        .first()
    )


def _prestamo_en_curso(db: Session, salon_id: int, utc: datetime) -> Optional[PrestamoSalon]:
    return (
        db.query(PrestamoSalon)
        .filter(
            PrestamoSalon.salon_id == salon_id,
            PrestamoSalon.estado.in_(["aprobado", "en_uso"]),
            PrestamoSalon.fecha_inicio <= utc,
            PrestamoSalon.fecha_fin > utc,
        )
        .order_by(PrestamoSalon.estado.desc())  # 'en_uso' antes que 'aprobado'
        .first()
    )


def _presencia(db: Session, horario_id: int, fecha: date) -> Optional[PresenciaSalon]:
    return (
        db.query(PresenciaSalon)
        .filter(PresenciaSalon.horario_id == horario_id, PresenciaSalon.fecha == fecha)
        .first()
    )


def _ocupacion_de(db: Session, salon: Salon, local: datetime) -> dict:
    utc = _a_utc_naive(local)
    clase = _clase_en_curso(db, salon.id, local)
    prestamo = _prestamo_en_curso(db, salon.id, utc)

    ocupante = "libre"
    clase_actual = None
    prestamo_actual = None
    profesor_presente = None

    if clase is not None:
        ocupante = "clase"
        clase_actual = {
            "horario_id": clase.id,
            "materia": clase.materia,
            "profesor": clase.profesor,
            "hora_inicio": clase.hora_inicio,
            "hora_fin": clase.hora_fin,
        }
        registro = _presencia(db, clase.id, local.date())
        profesor_presente = registro.profesor_presente if registro else None
    elif prestamo is not None:
        ocupante = "prestamo"

    if prestamo is not None:
        usuario = db.query(Usuario).filter(Usuario.id == prestamo.usuario_id).first()
        prestamo_actual = {
            "prestamo_id": prestamo.id,
            "usuario_id": prestamo.usuario_id,
            "usuario_nombre": usuario.nombre if usuario else f"Usuario #{prestamo.usuario_id}",
            "estado": prestamo.estado,
            "fecha_inicio": prestamo.fecha_inicio,
            "fecha_fin": prestamo.fecha_fin,
            "motivo": prestamo.motivo,
        }

    pendientes = (
        db.query(PrestamoSalon)
        .filter(PrestamoSalon.salon_id == salon.id, PrestamoSalon.estado == "pendiente")
        .count()
    )
    abiertos = (
        db.query(ReporteSalon)
        .filter(ReporteSalon.salon_id == salon.id, ReporteSalon.estado == "abierto")
        .count()
    )
    return {
        "salon": salon,
        "ocupante": ocupante,
        "clase_actual": clase_actual,
        "prestamo_actual": prestamo_actual,
        "profesor_presente": profesor_presente,
        "solicitudes_pendientes": pendientes,
        "reportes_abiertos": abiertos,
    }


def listar_ocupacion(db: Session, momento: Optional[datetime] = None) -> list[dict]:
    local = _ahora_campus(momento)
    salones = db.query(Salon).filter(Salon.activo.is_(True)).order_by(Salon.nombre).all()
    return [_ocupacion_de(db, s, local) for s in salones]


def obtener_ocupacion(db: Session, salon_id: int, momento: Optional[datetime] = None) -> dict:
    salon = obtener_salon(db, salon_id)
    return _ocupacion_de(db, salon, _ahora_campus(momento))


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
    db.commit()
    db.refresh(reporte)
    return reporte


def listar_reportes(
    db: Session, salon_id: int, estado: Optional[str] = None
) -> list[ReporteSalon]:
    obtener_salon(db, salon_id)
    query = db.query(ReporteSalon).filter(ReporteSalon.salon_id == salon_id)
    if estado:
        query = query.filter(ReporteSalon.estado == estado)
    return query.order_by(ReporteSalon.created_at.desc()).all()


def actualizar_estado_reporte(
    db: Session, salon_id: int, reporte_id: int, nuevo_estado: EstadoReporteSalon
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
    reporte.estado = nuevo_estado.value
    reporte.resuelto_en = (
        datetime.now(timezone.utc).replace(tzinfo=None)
        if nuevo_estado == EstadoReporteSalon.RESUELTO
        else None
    )
    db.commit()
    db.refresh(reporte)
    return reporte
