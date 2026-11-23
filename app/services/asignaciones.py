"""
Rol de las cuentas y carga masiva de roles (ADR-0024, reemplaza la regla automática de ADR-0019).

Decisión del dueño: se quita la verificación de correo y NADIE recibe un rol por escribir un
correo. Por eso:

- `rol_resuelto` es la ÚNICA función que dice qué rol tiene una cuenta: el rol guardado. Todo
  registro nace con el rol base (Estudiante); un rol con permisos solo lo pone un administrador
  sobre una cuenta que YA existe (pantalla Usuarios o la carga masiva de este módulo).
- La carga masiva (`correo,rol[,cargo]`) se aplica SOLO a cuentas existentes, con vista previa.
  Los correos sin cuenta se reportan como "sin cuenta" y NO quedan esperando: si esa persona se
  registra después, será Estudiante hasta que un administrador le dé el rol.
- Cada cambio sube `sesion_version` (cierra las sesiones de esa persona) y queda en la bitácora.
- Nunca se deja el sistema sin administrador activo.
"""
import csv
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core import permisos
from app.core.permisos import Rol
from app.core.politica import error_correo_nuevo, normalizar_correo, normalizar_nombre
from app.models.auth_models import Usuario
from app.services import auditoria
from app.services.usuarios import MSG_A_SI_MISMO, MSG_ULTIMO_ADMIN

ROL_BASE = Rol.ESTUDIANTE.value
MSG_ROL_INVALIDO = "Rol no válido: usa Estudiante, Auditor o Administrador"
MAX_LINEAS_IMPORTAR = 1000
CARGO_MAXIMO = 120

# Etiqueta o valor guardado -> valor guardado (la lista pegada puede usar cualquiera).
_ROLES_ESCRITOS = {
    **{r: r for r in permisos.ROLES_VALIDOS},
    **{etiqueta.lower(): valor for valor, etiqueta in permisos.ETIQUETAS.items()},
}

ORIGEN_MANUAL = "manual"
ORIGEN_BASE = "base"
TEXTO_ORIGEN = {
    ORIGEN_MANUAL: "Asignado por un administrador",
    ORIGEN_BASE: ("Eres estudiante. Si trabajas en la UTB y necesitas otro rol, pídeselo a "
                  "un administrador."),
}


def rol_resuelto(user: Usuario) -> str:
    """El rol de `user`: el guardado (un administrador lo puso) o, si no es válido, el base."""
    rol = permisos.normalizar_rol(user.rol)
    return rol if rol in permisos.ROLES_VALIDOS else ROL_BASE


def origen(user: Usuario) -> tuple[str, Optional[str]]:
    """(origen del rol, cargo) para el perfil."""
    return (ORIGEN_BASE if rol_resuelto(user) == ROL_BASE else ORIGEN_MANUAL), user.dependencia


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
    """Todo o nada: con un solo error no se aplica ninguna línea. Solo cuentas EXISTENTES.
    `actor` = None desde la consola."""
    actor_id = actor.id if actor else None
    filas, errores = analizar_lista(texto)
    resumen = {"validas": len(filas), "actualizadas": 0, "sin_cambios": 0, "sin_cuenta": 0,
               "correos_sin_cuenta": [], "errores": errores, "aplicado": False}
    cambios = []  # (usuario, fila)
    for fila in filas:
        user = _usuario_de(db, fila["correo"])
        if user is None:
            resumen["sin_cuenta"] += 1
            resumen["correos_sin_cuenta"].append(fila["correo"])
        elif permisos.normalizar_rol(user.rol) == fila["rol"] and (
                fila["cargo"] is None or fila["cargo"] == user.dependencia):
            resumen["sin_cambios"] += 1
        else:
            if actor and user.id == actor.id and permisos.normalizar_rol(user.rol) != fila["rol"]:
                errores.append({"linea": fila["linea"], "error": MSG_A_SI_MISMO})
                continue
            resumen["actualizadas"] += 1
            cambios.append((user, fila))
    if not errores and _quedaria_sin_admin(db, cambios):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=MSG_ULTIMO_ADMIN)
    if errores or simular:
        return resumen
    for user, fila in cambios:
        anterior = permisos.normalizar_rol(user.rol)
        if anterior != fila["rol"]:
            user.rol = fila["rol"]
            user.sesion_version = (user.sesion_version or 0) + 1
            auditoria.registrar(
                db, "usuario.rol", "usuario", user.id, actor_id=actor_id,
                detalle={"usuario": user.nombre, "de": anterior, "a": fila["rol"],
                         "via": "importacion"})
        user.rol_manual = True
        if fila["cargo"] is not None:
            user.dependencia = fila["cargo"]
    # Solo cifras: los correos importados no se copian a la bitácora.
    auditoria.registrar(db, "asignacion_rol.importar", "asignacion_rol", None, actor_id=actor_id,
                        detalle={**{k: resumen[k] for k in ("actualizadas", "sin_cambios", "sin_cuenta")},
                                 **({"origen": "consola"} if actor is None else {})})
    db.commit()
    resumen["aplicado"] = True
    return resumen


def _quedaria_sin_admin(db: Session, cambios: list) -> bool:
    """¿Tras aplicar `cambios` quedaría el sistema sin administrador activo?"""
    admin = Rol.ADMINISTRADOR.value
    restan = db.query(func.count(Usuario.id)).filter(
        func.lower(Usuario.rol) == admin, Usuario.activo.is_(True)).scalar() or 0
    for user, fila in cambios:
        era = permisos.normalizar_rol(user.rol) == admin and bool(user.activo)
        sera = fila["rol"] == admin and bool(user.activo)
        restan += int(sera) - int(era)
    return restan < 1
