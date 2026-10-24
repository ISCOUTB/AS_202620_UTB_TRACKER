"""
Capa de servicio para la gestión de recursos físicos e inventario (S9 — req. 9.6).

Provee operaciones de creación, consulta, actualización, reporte de novedades
y eliminación lógica (soft-delete) sobre equipos tecnológicos de la universidad.
"""
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import recurso_models
from app.models.auth_models import Usuario
from app.schemas import schemas


def crear_recurso(db: Session, datos: schemas.RecursoCreate) -> recurso_models.Recurso:
    """Crea un recurso nuevo. Rechaza con 409 si el serial ya existe."""
    existente = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.serial == datos.serial
    ).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya existe un recurso con ese serial")

    nuevo = recurso_models.Recurso(**datos.model_dump(), estado="disponible")
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


def listar_recursos(
    db: Session,
    salon_id: Optional[int] = None,
    categoria: Optional[str] = None,
    estado: Optional[str] = None,
    busqueda: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[recurso_models.Recurso], int]:
    """Devuelve recursos activos con filtros opcionales y paginación."""
    query = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.activo.is_(True)
    )
    if salon_id is not None:
        query = query.filter(recurso_models.Recurso.salon_id == salon_id)
    if categoria:
        query = query.filter(recurso_models.Recurso.categoria == categoria)
    if estado:
        query = query.filter(recurso_models.Recurso.estado == estado)
    if busqueda:
        query = query.filter(
            recurso_models.Recurso.serial.ilike(f"%{busqueda}%")
            | recurso_models.Recurso.descripcion.ilike(f"%{busqueda}%")
        )
    total = query.count()
    items = query.offset(skip).limit(limit).all()
    return items, total


def obtener_recurso(db: Session, recurso_id: int) -> recurso_models.Recurso:
    """Busca un recurso por ID. Lanza 404 si no existe."""
    recurso = db.query(recurso_models.Recurso).filter(
        recurso_models.Recurso.id == recurso_id,
        recurso_models.Recurso.activo.is_(True),
    ).first()
    if not recurso:
        raise HTTPException(status_code=404, detail="Recurso no encontrado")
    return recurso


def actualizar_recurso(
    db: Session, recurso_id: int, datos: schemas.RecursoUpdate
) -> recurso_models.Recurso:
    """Actualiza un recurso existente. Solo modifica campos proporcionados."""
    recurso = obtener_recurso(db, recurso_id)
    update_data = datos.model_dump(exclude_unset=True)

    # Si cambia el serial, verificar que no exista otro con el mismo
    if "serial" in update_data:
        existente = db.query(recurso_models.Recurso).filter(
            recurso_models.Recurso.serial == update_data["serial"],
            recurso_models.Recurso.id != recurso_id,
        ).first()
        if existente:
            raise HTTPException(status_code=409, detail="Ya existe un recurso con ese serial")

    for campo, valor in update_data.items():
        setattr(recurso, campo, valor)
    db.commit()
    db.refresh(recurso)
    return recurso


def eliminar_recurso(db: Session, recurso_id: int) -> dict:
    """Soft-delete: marca el recurso como inactivo."""
    recurso = obtener_recurso(db, recurso_id)
    recurso.activo = False
    db.commit()
    return {"message": "Recurso eliminado correctamente"}


def reportar_recurso(
    db: Session,
    recurso_id: int,
    datos: schemas.ReporteCreate,
    usuario_id: int,
) -> recurso_models.Reporte:
    """
    Crea un reporte de estado para un recurso.
    Actualiza el estado del recurso según lo reportado.
    """
    recurso = obtener_recurso(db, recurso_id)

    # Crear el registro de reporte
    reporte = recurso_models.Reporte(
        recurso_id=recurso_id,
        usuario_id=usuario_id,
        estado_reportado=datos.estado_reportado.value if hasattr(datos.estado_reportado, 'value') else datos.estado_reportado,
        descripcion=datos.descripcion,
        imagen_url=datos.imagen_url,
    )
    db.add(reporte)

    # Actualizar el estado del recurso
    recurso.estado = datos.estado_reportado.value if hasattr(datos.estado_reportado, 'value') else datos.estado_reportado
    if datos.imagen_url:
        recurso.imagen_url = datos.imagen_url

    db.commit()
    db.refresh(reporte)
    return reporte


def listar_reportes_recurso(
    db: Session, recurso_id: int
) -> list[recurso_models.Reporte]:
    """Devuelve el historial de reportes de un recurso."""
    # Verificar que el recurso existe
    obtener_recurso(db, recurso_id)
    return (
        db.query(recurso_models.Reporte)
        .filter(recurso_models.Reporte.recurso_id == recurso_id)
        .order_by(recurso_models.Reporte.created_at.desc())
        .all()
    )
