"""
Rol automático por correo institucional VERIFICADO (ADR-0019).

El correo @utb.edu.co no dice si alguien es estudiante o personal, así que el rol NO se deduce
del formato del correo: sale de la lista `asignaciones_rol` que mantiene el administrador
(correo exacto -> rol). Reglas:

- `rol_resuelto` es la ÚNICA función que decide el rol automático.
- Un rol manual (puesto por un administrador o la consola) gana siempre: no se recalcula.
- Sin correo COMPROBADO (verificado con un enlace o código que llegó a ese correo) el rol es el
  base: una cuenta que nació "verificada" porque no hay correo real no sube de rol.
- Si el rol cambia se cierran las sesiones (sube `sesion_version`) y queda en la bitácora.
- Nunca se deja el sistema sin administrador activo.
"""
import csv
import io
import logging
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core import permisos
from app.core.permisos import Rol
from app.core.politica import error_correo_nuevo, normalizar_correo, normalizar_nombre
from app.models.auth_models import AsignacionRol, Usuario
from app.services import auditoria
from app.services.correo import ocultar_correo
from app.services.usuarios import MSG_ULTIMO_ADMIN, administradores_activos

logger = logging.getLogger("utb_tracker")

ROL_BASE = Rol.ESTUDIANTE.value
MSG_NO_ENCONTRADA = "Asignación no encontrada"
MSG_YA_EXISTE = "Ese correo ya tiene una asignación. Edítala en lugar de crear otra."
MSG_ROL_INVALIDO = "Rol no válido: usa Estudiante, Auditor o Administrador"
MAX_LINEAS_IMPORTAR = 1000
CARGO_MAXIMO = 120

# Etiqueta o valor guardado -> valor guardado (la lista pegada puede usar cualquiera).
_ROLES_ESCRITOS = {
    **{r: r for r in permisos.ROLES_VALIDOS},
    **{etiqueta.lower(): valor for valor, etiqueta in permisos.ETIQUETAS.items()},
}

ORIGEN_MANUAL = "manual"
ORIGEN_CORREO = "correo"
ORIGEN_BASE = "base"
TEXTO_ORIGEN = {
    ORIGEN_MANUAL: "Asignado por un administrador",
    ORIGEN_CORREO: "Asignado por tu correo institucional",
    ORIGEN_BASE: ("Eres estudiante. Si trabajas en la UTB y necesitas otro rol, pídeselo a "
                  "un administrador."),
}


# --------------------------------------------------------------------------
# Resolución del rol
# --------------------------------------------------------------------------
def correo_comprobado(user: Usuario) -> bool:
    """¿La persona abrió un enlace o usó un código que llegó a su correo actual?"""
    return bool(user.email_verificado and user.email_verificado_en)


def buscar(db: Session, correo: str) -> Optional[AsignacionRol]:
    return db.query(AsignacionRol).filter(
        AsignacionRol.correo == normalizar_correo(correo)).first()


def rol_resuelto(db: Session, user: Usuario) -> str:
    """El rol que le toca a `user` según las reglas de arriba."""
    if user.rol_manual:
        return user.rol
    if not correo_comprobado(user):
        return ROL_BASE
    asignacion = buscar(db, user.email)
    return asignacion.rol if asignacion else ROL_BASE


def _quedaria_sin_admin(db: Session, user: Usuario, nuevo_rol: str) -> bool:
    return (
        permisos.normalizar_rol(user.rol) == Rol.ADMINISTRADOR.value and bool(user.activo)
        and nuevo_rol != Rol.ADMINISTRADOR.value and administradores_activos(db) <= 1
    )


def recalcular(db: Session, user: Usuario, motivo: str, actor_id: Optional[int] = None) -> bool:
    """Aplica `rol_resuelto` (sin commit). Devuelve True si el rol cambió."""
    nuevo = rol_resuelto(db, user)
    anterior = permisos.normalizar_rol(user.rol)
    if nuevo == anterior:
        return False
    if _quedaria_sin_admin(db, user, nuevo):
        logger.warning("No se recalcula el rol del usuario %s: es el último administrador", user.id)
        return False
    user.rol = nuevo
    user.sesion_version = (user.sesion_version or 0) + 1
    auditoria.registrar(db, "usuario.rol_automatico", "usuario", user.id, actor_id=actor_id,
                        detalle={"de": anterior, "a": nuevo, "motivo": motivo})
    return True


def origen(db: Session, user: Usuario) -> tuple[str, Optional[str]]:
    """(origen del rol, cargo de la asignación) para el perfil."""
    asignacion = buscar(db, user.email) if correo_comprobado(user) else None
    cargo = asignacion.cargo if asignacion else None
    if user.rol_manual:
        return ORIGEN_MANUAL, cargo
    if asignacion and asignacion.rol == user.rol and user.rol != ROL_BASE:
        return ORIGEN_CORREO, cargo
    return ORIGEN_BASE, cargo


# --------------------------------------------------------------------------
# Gestión de la lista (solo administrador)
# --------------------------------------------------------------------------
def _rol_valido(rol: str) -> str:
    valor = _ROLES_ESCRITOS.get((rol or "").strip().lower())
    if valor is None:
        raise ValueError(MSG_ROL_INVALIDO)
    return valor


def _correo_valido(correo: str) -> str:
    correo = normalizar_correo(correo)
    error = error_correo_nuevo(correo)
    if error:
        raise ValueError(error)
    return correo


def _cargo(cargo: Optional[str]) -> Optional[str]:
    limpio = normalizar_nombre(cargo or "")
    if len(limpio) > CARGO_MAXIMO:
        raise ValueError(f"El cargo debe tener como máximo {CARGO_MAXIMO} caracteres")
    return limpio or None


def _usuario_de(db: Session, correo: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(func.lower(Usuario.email) == correo).first()


def _proteger_y_aplicar(db: Session, correo: str, actor: Optional[Usuario], motivo: str) -> None:
    """Tras cambiar la lista: recalcula ya a la cuenta de ese correo (si la hay). 409 si el
    cambio dejaría el sistema sin administrador activo (la transacción no se confirma)."""
    user = _usuario_de(db, correo)
    if user is None:
        return
    if _quedaria_sin_admin(db, user, rol_resuelto(db, user)):
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_ULTIMO_ADMIN)
    recalcular(db, user, motivo, actor_id=actor.id if actor else None)


def _a_http(exc: ValueError) -> HTTPException:
    return HTTPException(status_code=422, detail=str(exc))


def listar(db: Session, busqueda: Optional[str] = None, rol: Optional[str] = None,
           skip: int = 0, limit: int = 50) -> tuple[list[AsignacionRol], int]:
    query = db.query(AsignacionRol)
    if busqueda and busqueda.strip():
        termino = f"%{busqueda.strip().lower()}%"
        query = query.filter(or_(AsignacionRol.correo.ilike(termino),
                                 AsignacionRol.cargo.ilike(termino)))
    if rol:
        query = query.filter(AsignacionRol.rol == permisos.normalizar_rol(rol))
    total = query.count()
    return query.order_by(AsignacionRol.correo.asc()).offset(skip).limit(limit).all(), total


def crear(db: Session, correo: str, rol: str, cargo: Optional[str], actor: Usuario) -> AsignacionRol:
    try:
        correo, rol, cargo = _correo_valido(correo), _rol_valido(rol), _cargo(cargo)
    except ValueError as exc:
        raise _a_http(exc) from exc
    if buscar(db, correo):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_YA_EXISTE)
    asignacion = AsignacionRol(correo=correo, rol=rol, cargo=cargo, creado_por_id=actor.id)
    db.add(asignacion)
    db.flush()
    auditoria.registrar(db, "asignacion_rol.crear", "asignacion_rol", asignacion.id,
                        actor_id=actor.id, detalle={"correo": ocultar_correo(correo), "rol": rol,
                                                    "cargo": cargo})
    _proteger_y_aplicar(db, correo, actor, "asignacion_creada")
    db.commit()
    db.refresh(asignacion)
    return asignacion


def _obtener(db: Session, asignacion_id: int) -> AsignacionRol:
    asignacion = db.get(AsignacionRol, asignacion_id)
    if asignacion is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_NO_ENCONTRADA)
    return asignacion


def editar(db: Session, asignacion_id: int, datos: dict, actor: Usuario) -> AsignacionRol:
    asignacion = _obtener(db, asignacion_id)
    cambios = {}
    try:
        if datos.get("rol") is not None:
            cambios["rol"] = _rol_valido(datos["rol"])
        if "cargo" in datos:
            cambios["cargo"] = _cargo(datos["cargo"])
    except ValueError as exc:
        raise _a_http(exc) from exc
    cambios = {k: v for k, v in cambios.items() if getattr(asignacion, k) != v}
    if not cambios:
        return asignacion
    antes = {k: getattr(asignacion, k) for k in cambios}
    for campo, valor in cambios.items():
        setattr(asignacion, campo, valor)
    auditoria.registrar(db, "asignacion_rol.editar", "asignacion_rol", asignacion.id,
                        actor_id=actor.id, detalle={"correo": ocultar_correo(asignacion.correo),
                                                    "de": antes, "a": cambios})
    _proteger_y_aplicar(db, asignacion.correo, actor, "asignacion_editada")
    db.commit()
    db.refresh(asignacion)
    return asignacion


def eliminar(db: Session, asignacion_id: int, actor: Usuario) -> None:
    asignacion = _obtener(db, asignacion_id)
    correo, rol = asignacion.correo, asignacion.rol
    db.delete(asignacion)
    db.flush()
    auditoria.registrar(db, "asignacion_rol.eliminar", "asignacion_rol", asignacion_id,
                        actor_id=actor.id, detalle={"correo": ocultar_correo(correo), "rol": rol})
    _proteger_y_aplicar(db, correo, actor, "asignacion_eliminada")
    db.commit()


def _es_linea_ignorable(numero: int, campos: list[str]) -> bool:
    if not campos or not "".join(campos).strip() or campos[0].lstrip().startswith("#"):
        return True
    if numero == 1 and campos[0].strip().lower() in ("correo", "email"):
        return True
    return False


def _validar_campos_linea(
    numero: int, campos: list[str], vistos: dict[str, int],
) -> tuple[Optional[dict], Optional[dict]]:
    if len(campos) < 2 or len(campos) > 3:
        return None, {"linea": numero, "error": "Formato: correo,rol[,cargo]"}
    try:
        correo = _correo_valido(campos[0])
        rol = _rol_valido(campos[1])
        cargo = _cargo(campos[2] if len(campos) == 3 else None)
    except ValueError as exc:
        return None, {"linea": numero, "error": str(exc)}
    if correo in vistos:
        return None, {
            "linea": numero,
            "error": f"Correo repetido (ya está en la línea {vistos[correo]})",
        }
    vistos[correo] = numero
    return {"linea": numero, "correo": correo, "rol": rol, "cargo": cargo}, None


def analizar_lista(texto: str) -> tuple[list[dict], list[dict]]:
    """Lista pegada o CSV: `correo,rol[,cargo]` por línea (coma o punto y coma).

    Devuelve (filas válidas, errores por línea). Admite una fila de encabezado y líneas
    vacías o que empiezan con '#'. El rol puede ser la etiqueta (Auditor) o el valor (auxiliar).
    """
    lineas = (texto or "").splitlines()
    primera = next((l for l in lineas if l.strip() and not l.lstrip().startswith("#")), "")
    separador = ";" if primera.count(";") > primera.count(",") else ","
    filas, errores, vistos = [], [], {}
    for numero, campos in enumerate(csv.reader(lineas, delimiter=separador), start=1):
        if _es_linea_ignorable(numero, campos):
            continue
        if len(filas) + len(errores) >= MAX_LINEAS_IMPORTAR:
            errores.append({"linea": numero,
                            "error": f"Máximo {MAX_LINEAS_IMPORTAR} líneas por importación"})
            break
        fila, err = _validar_campos_linea(numero, campos, vistos)
        if err:
            errores.append(err)
        elif fila:
            filas.append(fila)
    if not filas and not errores:
        errores.append({"linea": 0, "error": "La lista está vacía"})
    return filas, errores


def importar(db: Session, texto: str, simular: bool, actor: Optional[Usuario]) -> dict:
    """Todo o nada: con un solo error no se aplica ninguna línea. `actor` = None desde la
    consola (scripts/cargar_asignaciones.py)."""
    actor_id = actor.id if actor else None
    filas, errores = analizar_lista(texto)
    resumen = {"validas": len(filas), "creadas": 0, "actualizadas": 0, "sin_cambios": 0,
               "errores": errores, "aplicado": False}
    for fila in filas:
        existente = buscar(db, fila["correo"])
        if existente is None:
            resumen["creadas"] += 1
        elif (existente.rol, existente.cargo) != (fila["rol"], fila["cargo"]):
            resumen["actualizadas"] += 1
        else:
            resumen["sin_cambios"] += 1
    if errores or simular:
        return resumen
    for fila in filas:
        existente = buscar(db, fila["correo"])
        if existente is None:
            db.add(AsignacionRol(correo=fila["correo"], rol=fila["rol"], cargo=fila["cargo"],
                                 creado_por_id=actor_id))
        else:
            existente.rol, existente.cargo = fila["rol"], fila["cargo"]
    db.flush()
    for fila in filas:
        _proteger_y_aplicar(db, fila["correo"], actor, "asignacion_importada")
    # Solo cifras: los correos importados no se copian a la bitácora.
    detalle = {k: resumen[k] for k in ("creadas", "actualizadas", "sin_cambios")}
    if actor is None:
        detalle["origen"] = "consola"
    auditoria.registrar(db, "asignacion_rol.importar", "asignacion_rol", None, actor_id=actor_id,
                        detalle=detalle)
    db.commit()
    resumen["aplicado"] = True
    return resumen


def volver_a_automatico(db: Session, usuario_id: int, actor: Usuario) -> Usuario:
    """Quita la marca manual: desde ahora manda la lista (y se recalcula ya)."""
    user = db.get(Usuario, usuario_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    if user.id == actor.id:
        from app.services.usuarios import MSG_A_SI_MISMO
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_A_SI_MISMO)
    if not user.rol_manual:
        return user
    user.rol_manual = False
    if _quedaria_sin_admin(db, user, rol_resuelto(db, user)):
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_ULTIMO_ADMIN)
    auditoria.registrar(db, "usuario.rol_automatico_activado", "usuario", user.id,
                        actor_id=actor.id, detalle={"usuario": user.nombre})
    recalcular(db, user, "vuelve_a_automatico", actor_id=actor.id)
    db.commit()
    db.refresh(user)
    return user
