"""
Capa de servicio para el módulo de Horarios.

CRUD de horarios académicos con validación de conflictos temporales,
soporte para carga masiva por semestre.
"""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import cast, String

from app.models.salon_models import Horario, Salon
from app.schemas.horarios import HorarioCreate, HorarioUpdate


def _validar_salon_existe(db: Session, salon_id: int) -> Salon:
    """Verifica que el salón exista."""
    salon = db.query(Salon).filter(Salon.id == salon_id, Salon.activo.is_(True)).first()
    if not salon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Salón no encontrado",
        )
    return salon


def _detectar_conflicto(db: Session, salon_id: int, dia_semana: int, hora_inicio, hora_fin, excluir_id: int | None = None):
    """Verifica que no exista un horario que se cruce en el mismo salón y día."""
    # Convertir a string ISO para compatibilidad con SQLite (almacena Time como texto)
    h_inicio_str = hora_inicio.isoformat() if hasattr(hora_inicio, "isoformat") else str(hora_inicio)
    h_fin_str = hora_fin.isoformat() if hasattr(hora_fin, "isoformat") else str(hora_fin)

    
    query = db.query(Horario).filter(
        Horario.salon_id == salon_id,
        Horario.dia_semana == dia_semana,
        Horario.activo.is_(True),
        cast(Horario.hora_inicio, String) < h_fin_str,
        cast(Horario.hora_fin, String) > h_inicio_str,
    )
    if excluir_id:
        query = query.filter(Horario.id != excluir_id)
    conflicto = query.first()
    if conflicto:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Conflicto con horario existente: {conflicto.materia or 'sin materia'} "
                   f"({conflicto.hora_inicio}-{conflicto.hora_fin})",
        )


def crear_horario(db: Session, datos: HorarioCreate) -> Horario:
    """Crea un horario académico validando que no haya conflictos temporales."""
    _validar_salon_existe(db, datos.salon_id)
    _detectar_conflicto(db, datos.salon_id, datos.dia_semana, datos.hora_inicio, datos.hora_fin)

    nuevo = Horario(**datos.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


def crear_horarios_bulk(db: Session, items: list[HorarioCreate]) -> list[Horario]:
    """Carga masiva de horarios. Valida conflictos para cada uno."""
    creados = []
    for datos in items:
        _validar_salon_existe(db, datos.salon_id)
        _detectar_conflicto(db, datos.salon_id, datos.dia_semana, datos.hora_inicio, datos.hora_fin)
        nuevo = Horario(**datos.model_dump())
        db.add(nuevo)
        creados.append(nuevo)
    db.commit()
    for h in creados:
        db.refresh(h)
    return creados


def listar_horarios(
    db: Session,
    salon_id: int | None = None,
    dia_semana: int | None = None,
    semestre: str | None = None,
) -> list[Horario]:
    """Devuelve horarios activos con filtros opcionales."""
    query = db.query(Horario).filter(Horario.activo.is_(True))
    if salon_id is not None:
        query = query.filter(Horario.salon_id == salon_id)
    if dia_semana is not None:
        query = query.filter(Horario.dia_semana == dia_semana)
    if semestre:
        query = query.filter(Horario.semestre == semestre)
    return query.order_by(Horario.dia_semana, Horario.hora_inicio).all()


def obtener_horario(db: Session, horario_id: int) -> Horario:
    """Busca un horario por ID. Lanza 404 si no existe."""
    horario = db.query(Horario).filter(
        Horario.id == horario_id, Horario.activo.is_(True)
    ).first()
    if not horario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Horario no encontrado"
        )
    return horario


def actualizar_horario(db: Session, horario_id: int, datos: HorarioUpdate) -> Horario:
    """Actualiza un horario existente validando conflictos si cambian las horas."""
    horario = obtener_horario(db, horario_id)
    update_data = datos.model_dump(exclude_unset=True)

    # Si cambian día u horas, validar conflictos
    dia = update_data.get("dia_semana", horario.dia_semana)
    inicio = update_data.get("hora_inicio", horario.hora_inicio)
    fin = update_data.get("hora_fin", horario.hora_fin)
    if any(k in update_data for k in ("dia_semana", "hora_inicio", "hora_fin")):
        _detectar_conflicto(db, horario.salon_id, dia, inicio, fin, excluir_id=horario_id)

    for campo, valor in update_data.items():
        setattr(horario, campo, valor)
    db.commit()
    db.refresh(horario)
    return horario


def eliminar_horario(db: Session, horario_id: int) -> dict:
    """Soft-delete: marca el horario como inactivo."""
    horario = obtener_horario(db, horario_id)
    horario.activo = False
    db.commit()
    return {"message": "Horario eliminado correctamente"}
