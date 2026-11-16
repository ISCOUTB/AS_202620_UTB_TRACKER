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
from app.core import permisos
from app.services import auditoria, catalogo, equipamiento, estado_salon

# Clientes viejos mandan `estado`; ahora se traduce a la habilitación (ADR-0022).
_ESTADO_A_MOTIVO = {"mantenimiento": "mantenimiento", "fuera_servicio": "danio"}

# Campos que definen el salón en el catálogo: solo el Administrador los cambia (ADR-0021).
CAMPOS_CATALOGO = ("nombre", "edificio", "piso")


def crear_salon(db: Session, datos: SalonCreate, actor_id: Optional[int] = None) -> Salon:
    """Crea un salón nuevo. Valida el código del catálogo (ADR-0021); 409 si el nombre ya existe."""
    valores = catalogo.completar(datos.model_dump(mode="json"))
    catalogo.validar(valores["nombre"], valores.get("edificio"), valores.get("piso"))
    existente = db.query(Salon).filter(Salon.nombre == valores["nombre"]).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un salón con ese nombre",
        )
    # `estado` de un cliente viejo -> habilitación (ADR-0022). "ocupado" no se guarda.
    estado = valores.pop("estado", "disponible")
    nuevo = Salon(**valores, estado="disponible")
    if estado in _ESTADO_A_MOTIVO:
        nuevo.habilitado = False
        nuevo.motivo_deshabilitado = _ESTADO_A_MOTIVO[estado]
        nuevo.estado = estado
    db.add(nuevo)
    db.flush()
    auditoria.registrar(
        db, "salon.crear", "salon", nuevo.id, actor_id=actor_id,
        detalle={"nombre": nuevo.nombre, "capacidad": nuevo.capacidad, "tipo": nuevo.tipo},
    )
    db.commit()
    db.refresh(nuevo)
    return equipamiento.adjuntar(db, [nuevo])[0]


def listar_salones(
    db: Session,
    skip: int = 0,
    limit: int = 50,
    estado: Optional[str] = None,
    edificio: Optional[str] = None,
    busqueda: Optional[str] = None,
    tipo: Optional[str] = None,
    con_equipo: Optional[str] = None,
    piso: Optional[int] = None,
) -> tuple[list[Salon], int]:
    """Devuelve salones activos con filtros opcionales y paginación.

    - tipo: aula, laboratorio_computo… (ADR-0017)
    - con_equipo: categoría de recurso; solo salones con al menos uno OPERATIVO.
    - busqueda: en el nombre y en la descripción.
    El equipamiento de todos los salones de la página se calcula en UNA consulta.
    """
    query = db.query(Salon).filter(Salon.activo.is_(True))
    if estado == "disponible":
        query = query.filter(Salon.habilitado.is_(True))
    elif estado in ("mantenimiento", "fuera_servicio"):
        query = query.filter(Salon.estado == estado)
    elif estado == "ocupado":
        query = query.filter(Salon.habilitado.is_(True))
    if edificio:
        query = query.filter(Salon.edificio == edificio)
    if piso is not None:
        query = query.filter(Salon.piso == piso)
    if tipo:
        query = query.filter(Salon.tipo == tipo)
    if con_equipo:
        query = query.filter(equipamiento.filtro_con_equipo(con_equipo))
    if busqueda:
        termino = f"%{busqueda.strip()}%"
        query = query.filter(Salon.nombre.ilike(termino) | Salon.descripcion.ilike(termino))
    total = query.count()
    # Orden natural de los códigos (A1-101, A1-102 … A1-201 … A2-201): con el formato fijo de
    # ADR-0021 el orden alfabético del nombre ES el natural, así que se hace en la base.
    items = equipamiento.adjuntar(db, query.order_by(Salon.nombre).offset(skip).limit(limit).all())
    if estado in ("disponible", "ocupado"):  # la ocupación se calcula: se filtra al final
        items = [s for s in items if s.estado_visible == estado]
    return items, total


def obtener_salon_con_equipamiento(db: Session, salon_id: int) -> Salon:
    return equipamiento.adjuntar(db, [obtener_salon(db, salon_id)])[0]


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
    db: Session, salon_id: int, datos: SalonUpdate, actor_id: Optional[int] = None,
    actor_rol: Optional[str] = None,
) -> Salon:
    """Actualiza un salón existente. Solo modifica campos proporcionados.

    Renombrar o cambiar edificio/piso es del catálogo: solo el Administrador (403 al Auditor).
    """
    salon = obtener_salon(db, salon_id)
    update_data = datos.model_dump(exclude_unset=True, mode="json")
    # Columnas obligatorias en la base: "null" no las borra.
    for campo in ("tipo", "nombre", "ubicacion", "capacidad", "estado"):
        if campo in update_data and update_data[campo] is None:
            update_data.pop(campo)
    toca_catalogo = any(
        c in update_data and update_data[c] != getattr(salon, c) for c in CAMPOS_CATALOGO
    )
    if toca_catalogo:
        if actor_rol is not None and not permisos.tiene(
            actor_rol, permisos.Permiso.SALONES_CREAR_CATALOGO
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Solo un administrador puede renombrar un salón o cambiar su edificio o piso.",
            )
        nombre = catalogo.normalizar_codigo(update_data.get("nombre", salon.nombre))             if catalogo.es_codigo_de_catalogo(update_data.get("nombre", salon.nombre))             else update_data.get("nombre", salon.nombre)
        catalogo.validar(nombre, update_data.get("edificio", salon.edificio),
                         update_data.get("piso", salon.piso))
        if "nombre" in update_data:
            update_data["nombre"] = nombre
            if db.query(Salon.id).filter(Salon.nombre == nombre, Salon.id != salon.id).first():
                raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                                    detail="Ya existe un salón con ese nombre")
    if "capacidad" in update_data and update_data["capacidad"] is not None:
        update_data["capacidad_estimada"] = False
    # Un cliente viejo cambia `estado` a mano: se traduce a habilitar/deshabilitar (con su
    # historial y auditoría). "ocupado" se ignora: ahora se calcula.
    estado = update_data.pop("estado", None)
    if estado == "disponible" and not salon.habilitado:
        estado_salon.cambiar_habilitacion(db, salon, True, None, None, None, actor_id, commit=False)
    elif estado in _ESTADO_A_MOTIVO and (
        salon.habilitado or salon.motivo_deshabilitado != _ESTADO_A_MOTIVO[estado]
    ):
        estado_salon.cambiar_habilitacion(db, salon, False, _ESTADO_A_MOTIVO[estado],
                                          salon.nota_deshabilitado, None, actor_id, commit=False)
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
    return equipamiento.adjuntar(db, [salon])[0]


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
    salon = obtener_salon(db, salon_id)
    if not salon.habilitado:
        return []  # deshabilitado (ADR-0022): no tiene franjas para pedir

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
