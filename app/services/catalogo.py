"""
Catálogo de salones de la UTB (ADR-0021).

Regla ÚNICA del código (aquí y en ningún otro lugar del backend; espejo en
frontend/lib/features/salones_admin/domain/catalogo.dart):

    A + edificio (1 dígito) + "-" + piso (1 dígito) + salón (2 dígitos)
    A1-101 = edificio A1, piso 1, salón 01.  A2-505 = edificio A2, piso 5, salón 05.

El edificio y el piso guardados deben COINCIDIR con los dígitos del código.

Los nombres que NO empiezan por "A<dígito>" (por ejemplo "Auditorio Napoleón de la Rosa") son
espacios especiales: se aceptan sin esta regla. Así no se rompen los salones reales que ya se
crearon a mano ni los nombres de espacios que no son aulas.

El catálogo inicial vive en un archivo de DATOS (scripts/datos/catalogo_utb.json): se corrige
sin tocar código. Nada de aquí borra salones.
"""
import json
import re
from pathlib import Path
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.services import auditoria

PATRON_CODIGO = re.compile(r"^A(\d)-(\d)(\d{2})$")
_PARECE_CODIGO = re.compile(r"^A\d")
ARCHIVO_CATALOGO = Path(__file__).resolve().parents[2] / "scripts" / "datos" / "catalogo_utb.json"
MAX_POR_LOTE = 99


def normalizar_codigo(nombre: str) -> str:
    """' a1-101 ' -> 'A1-101' (mayúsculas, sin espacios)."""
    return "".join((nombre or "").split()).upper()


def es_codigo_de_catalogo(nombre: str) -> bool:
    """¿El nombre debe seguir la regla? (empieza por A + dígito)."""
    return bool(_PARECE_CODIGO.match(normalizar_codigo(nombre)))


def edificio_de(numero: int) -> str:
    return f"A{numero}"


def ubicacion_de(edificio: str, piso: int) -> str:
    return f"Edificio {edificio}, piso {piso}"


def errores_codigo(nombre: str, edificio: Optional[str], piso: Optional[int]) -> list[str]:
    """Lista de problemas en español (vacía = válido). Solo para nombres con forma de código."""
    codigo = normalizar_codigo(nombre)
    m = PATRON_CODIGO.match(codigo)
    if not m:
        return ["El código debe tener la forma A1-101: A, edificio (1 dígito), guion, "
                "piso (1 dígito) y salón (2 dígitos)."]
    errores = []
    if m.group(3) == "00":
        errores.append("El número de salón no puede ser 00.")
    if edificio is not None and (edificio or "").strip().upper() != edificio_de(int(m.group(1))):
        errores.append(f"El edificio debe ser {edificio_de(int(m.group(1)))} según el código.")
    if piso is not None and piso != int(m.group(2)):
        errores.append(f"El piso debe ser {m.group(2)} según el código.")
    return errores


def validar(nombre: str, edificio: Optional[str], piso: Optional[int]) -> None:
    """422 con el primer problema si el nombre tiene forma de código y no cumple la regla."""
    if not es_codigo_de_catalogo(nombre):
        return
    errores = errores_codigo(nombre, edificio, piso)
    if errores:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=errores[0])


def completar(datos: dict) -> dict:
    """Para un código válido: nombre en mayúsculas, edificio/piso deducidos si faltan y la
    ubicación legible SIEMPRE derivada del código ("Edificio A2, piso 5")."""
    if not es_codigo_de_catalogo(datos.get("nombre", "")):
        return datos
    datos["nombre"] = normalizar_codigo(datos["nombre"])
    m = PATRON_CODIGO.match(datos["nombre"])
    if m:
        edificio = edificio_de(int(m.group(1)))
        if datos.get("edificio") in (None, ""):
            datos["edificio"] = edificio
        else:
            datos["edificio"] = datos["edificio"].strip().upper()
        if datos.get("piso") is None:
            datos["piso"] = int(m.group(2))
        datos["ubicacion"] = ubicacion_de(edificio, int(m.group(2)))
    return datos


def codigos_de_rango(edificio: int, piso: int, desde: int, hasta: int) -> list[str]:
    if not (1 <= edificio <= 9 and 1 <= piso <= 9 and 1 <= desde <= hasta <= 99):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Rango inválido: edificio y piso de 1 a 9; salones de 01 a 99 y 'desde' ≤ 'hasta'.",
        )
    return [f"A{edificio}-{piso}{n:02d}" for n in range(desde, hasta + 1)]


def clave_orden(nombre: str) -> tuple:
    """Orden natural: A1-101, A1-102 … A1-201 … A2-201; los espacios especiales al final."""
    m = PATRON_CODIGO.match(normalizar_codigo(nombre))
    if m:
        return (0, int(m.group(1)), int(m.group(2)), int(m.group(3)), "")
    return (1, 0, 0, 0, nombre.lower())


# ── Crear varios por rango (pantalla del administrador) ──────────────────────

def vista_previa_rango(db: Session, edificio: int, piso: int, desde: int, hasta: int) -> dict:
    """Qué se crearía y qué ya existe. No escribe nada."""
    codigos = codigos_de_rango(edificio, piso, desde, hasta)
    existentes = {
        n for (n,) in db.query(Salon.nombre).filter(Salon.nombre.in_(codigos)).all()
    }
    return {
        "edificio": edificio_de(edificio),
        "piso": piso,
        "ubicacion": ubicacion_de(edificio_de(edificio), piso),
        "nuevos": [c for c in codigos if c not in existentes],
        "existentes": [c for c in codigos if c in existentes],
    }


def crear_rango(
    db: Session, edificio: int, piso: int, desde: int, hasta: int,
    capacidad: int, tipo: str, actor_id: Optional[int],
) -> dict:
    """Crea los del rango que falten (los existentes no se tocan). Una sola transacción."""
    previa = vista_previa_rango(db, edificio, piso, desde, hasta)
    estimada = capacidad is None
    creados = []
    for codigo in previa["nuevos"]:
        salon = Salon(
            nombre=codigo, edificio=previa["edificio"], piso=piso,
            ubicacion=previa["ubicacion"], capacidad=capacidad or 40,
            capacidad_estimada=estimada, tipo=tipo, estado="disponible",
        )
        db.add(salon)
        creados.append(salon)
    db.flush()
    if creados:
        auditoria.registrar(
            db, "salon.crear_lote", "salon", None, actor_id=actor_id,
            detalle={"edificio": previa["edificio"], "piso": piso,
                     "creados": [s.nombre for s in creados], "omitidos": previa["existentes"]},
        )
    db.commit()
    return {**previa, "creados": [s.nombre for s in creados]}


# ── Reconciliación: salones existentes que no siguen la regla ────────────────

def _con_historial(db: Session, ids: list[int]) -> set[int]:
    if not ids:
        return set()
    con_solicitudes = {i for (i,) in db.query(PrestamoSalon.salon_id)
                       .filter(PrestamoSalon.salon_id.in_(ids)).distinct().all()}
    con_clases = {i for (i,) in db.query(Horario.salon_id)
                  .filter(Horario.salon_id.in_(ids)).distinct().all()}
    return con_solicitudes | con_clases


def fuera_del_catalogo(db: Session, catalogo: Optional[set[str]] = None) -> list[dict]:
    """Reporte (solo lectura) con una PROPUESTA por salón. El administrador decide; nada se borra.

    - Sin forma de código: espacio especial o dato viejo -> revisar / desactivar si no se usa.
    - Con forma de código pero mal formado o con edificio/piso que no coinciden -> corregir.
    - Bien formado pero fuera del catálogo provisional -> confirmar con Planta Física.
    """
    if catalogo is None:
        catalogo = set(cargar_archivo()["codigos"])
    salones = db.query(Salon).filter(Salon.activo.is_(True)).all()
    historial = _con_historial(db, [s.id for s in salones])
    reporte = []
    for s in sorted(salones, key=lambda x: clave_orden(x.nombre)):
        usado = s.id in historial
        if not es_codigo_de_catalogo(s.nombre):
            problema = "No sigue el formato A1-101 (espacio especial o dato viejo)."
            propuesta = ("Dejarlo como espacio especial o renombrarlo; tiene historial, no borrar."
                         if usado else "Dejarlo como espacio especial o desactivarlo si no existe.")
        else:
            errores = errores_codigo(s.nombre, s.edificio, s.piso)
            if errores:
                problema = " ".join(errores)
                m = PATRON_CODIGO.match(normalizar_codigo(s.nombre))
                propuesta = (f"Corregir edificio a {edificio_de(int(m.group(1)))} y piso a "
                             f"{m.group(2)}." if m else "Renombrar con el formato A1-101.")
            elif normalizar_codigo(s.nombre) not in catalogo:
                problema = "Bien formado, pero no está en el catálogo provisional."
                propuesta = "Confirmar con Planta Física; si existe, agregarlo al catálogo."
            else:
                continue
        reporte.append({
            "id": s.id, "nombre": s.nombre, "edificio": s.edificio, "piso": s.piso,
            "tiene_historial": usado, "problema": problema, "propuesta": propuesta,
        })
    return reporte


# ── Archivo de datos y carga idempotente (scripts/cargar_catalogo_utb.py) ────

def cargar_archivo(ruta: Path = ARCHIVO_CATALOGO) -> dict:
    """Lee el JSON y devuelve {'codigos': [...], 'tipos': {...}, 'capacidad': int}."""
    datos = json.loads(Path(ruta).read_text(encoding="utf-8"))
    codigos: list[str] = []
    for r in datos["rangos"]:
        codigos += codigos_de_rango(r["edificio"], r["piso"], r["desde"], r["hasta"])
    tipos = {k: v for k, v in datos.get("tipos", {}).items() if not k.startswith("_")}
    return {"codigos": codigos, "tipos": tipos,
            "capacidad": int(datos.get("capacidad_por_defecto", 40))}


def aplicar_catalogo(db: Session, catalogo: dict, simular: bool) -> dict:
    """Crea los salones del catálogo que falten. NUNCA borra ni modifica los existentes."""
    from app.schemas.enums import TipoSalon
    validos = {t.value for t in TipoSalon}
    existentes = {n for (n,) in db.query(Salon.nombre).all()}
    creados, omitidos = [], []
    for codigo in catalogo["codigos"]:
        if codigo in existentes:
            omitidos.append(codigo)
            continue
        m = PATRON_CODIGO.match(codigo)
        edificio, piso = edificio_de(int(m.group(1))), int(m.group(2))
        tipo = catalogo["tipos"].get(codigo, "aula")
        if tipo not in validos:
            raise ValueError(f"Tipo inválido para {codigo}: {tipo}")
        creados.append(codigo)
        if not simular:
            db.add(Salon(
                nombre=codigo, edificio=edificio, piso=piso, ubicacion=ubicacion_de(edificio, piso),
                capacidad=catalogo["capacidad"], capacidad_estimada=True, tipo=tipo,
                estado="disponible",
            ))
    if not simular:
        if creados:
            auditoria.registrar(
                db, "salon.catalogo.cargar", "salon", None, actor_nombre="script catálogo UTB",
                detalle={"creados": len(creados), "omitidos": len(omitidos)},
            )
        db.commit()
    return {"creados": creados, "omitidos": omitidos}

