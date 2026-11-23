"""
Agrega EQUIPOS FIJOS de ejemplo a los salones que YA existen del catálogo (ADR-0021, ADR-0010).

- NO crea salones y NO borra nada. Solo agrega equipos que falten; repetible (por número de serie).
- Todos los seriales empiezan por `DEMO-` para identificarlos y limpiarlos después:
      python scripts/cargar_equipos_demo.py --quitar     # quita SOLO los DEMO-... sin reportes
- Datos ficticios, para la exposición. Reglas (decididas por el dueño):
    · Aulas: video beam, tablero, aire acondicionado o ventiladores, sonido básico en algunas.
    · A1-402 a A1-407 (el catálogo los marca como laboratorio_computo): SALAS DE COMPUTADORES.
    · Edificio A5: LABORATORIOS DE QUÍMICA (mesones, campana, lavaojos y ducha, extintor, kit de
      derrames, balanzas, planchas, video beam y tablero).
    · Auditorios y salas de reuniones (si el catálogo los trae): sonido, micrófonos, proyector grande.
- Unos pocos equipos dañados o en mantenimiento y UN salón deshabilitado (A3-102) para mostrar
  el estado y la habilitación.

    python scripts/cargar_equipos_demo.py --simular    # solo cuenta, no guarda
    python scripts/cargar_equipos_demo.py              # agrega
"""
import argparse
import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core import config  # noqa: E402
from app.core.database import SessionLocal  # noqa: E402
from app.models import Recurso, Salon, Usuario  # noqa: E402
from app.models.salon_models import HistorialSalon  # noqa: E402

PREFIJO = "DEMO-"
ARCHIVO_CATALOGO = Path(__file__).resolve().parent / "datos" / "catalogo_utb.json"


def codigos_del_catalogo() -> set[str]:
    """Los códigos A1-101… del catálogo oficial del proyecto (los únicos que reciben equipos)."""
    datos = json.loads(ARCHIVO_CATALOGO.read_text(encoding="utf-8"))
    return {f"A{r['edificio']}-{r['piso']}{n:02d}"
            for r in datos["rangos"] for n in range(r["desde"], r["hasta"] + 1)}

# Salas de computadores: computadores por sala (el catálogo estima capacidad 40).
PCS_POR_SALA = {"A1-402": 30, "A1-403": 40, "A1-404": 24, "A1-405": 36, "A1-406": 28, "A1-407": 32}

QUIMICA = [  # (categoría, clave, descripción)
    ("otro", "MESON", "Mesones de laboratorio con poceta (6 puestos)"),
    ("otro", "CAMPANA", "Campana extractora de gases"),
    ("otro", "LAVAOJOS", "Lavaojos de emergencia"),
    ("otro", "DUCHA", "Ducha de emergencia"),
    ("otro", "EXTINTOR", "Extintor multipropósito"),
    ("otro", "DERRAMES", "Kit de control de derrames"),
    ("otro", "BALANZA", "Balanzas analíticas (3)"),
    ("otro", "PLANCHA", "Planchas de calentamiento con agitación (4)"),
    ("video_beam", "VB", "Video beam BenQ"),
    ("otro", "TABLERO", "Tablero acrílico"),
]

AUDITORIO = [
    ("video_beam", "VB", "Proyector grande de 7000 lúmenes"),
    ("audio", "AU", "Consola de sonido y parlantes"),
    ("audio", "MIC", "Micrófonos inalámbricos (4)"),
    ("aire_ac", "AC", "Aire acondicionado central"),
]
REUNIONES = [
    ("tv", "TV", "Pantalla de 65 pulgadas"),
    ("audio", "AU", "Barra de sonido"),
    ("aire_ac", "AC", "Aire acondicionado 18000 BTU"),
    ("otro", "TABLERO", "Tablero acrílico"),
]

# Equipos con novedades (serial -> (estado, nota)) para que la demo se vea viva.
NOVEDADES = {
    "DEMO-VB-A2-203": ("dañado", "Lámpara quemada"),
    "DEMO-AC-A1-104": ("dañado", "No enfría"),
    "DEMO-PC-A1-404-07": ("dañado", "No enciende"),
    "DEMO-CAMPANA-A5-203": ("mantenimiento", "Calibración del extractor"),
    "DEMO-PC-A1-406-12": ("mantenimiento", "Formateo programado"),
    "DEMO-VB-A4-103": ("mantenimiento", "Cambio de lámpara"),
    "DEMO-BALANZA-A5-202": ("dañado", "Pantalla sin lectura"),
}
SALON_DESHABILITADO = ("A3-102", "mantenimiento", "Pintura del salón y cambio de lámpara")


def equipos_de(salon: Salon) -> list[tuple[str, str, str]]:
    """(categoría, serial, descripción) que le corresponden a un salón del catálogo."""
    c = salon.nombre
    tipo = (salon.tipo or "aula").lower()
    filas: list[tuple[str, str, str]] = []

    def f(cat, clave, desc):
        filas.append((cat, f"{PREFIJO}{clave}-{c}", desc))

    if c in PCS_POR_SALA or tipo == "laboratorio_computo":
        for n in range(1, PCS_POR_SALA.get(c, 24) + 1):
            filas.append(("computador", f"{PREFIJO}PC-{c}-{n:02d}", "Computador de estudiante"))
        f("video_beam", "VB", "Video beam Epson PowerLite")
        f("otro", "TABLERO", "Tablero acrílico")
        f("aire_ac", "AC", "Aire acondicionado 36000 BTU")
        f("otro", "RED", "Switch de red de 48 puertos")
    elif c.startswith("A5-"):
        for cat, clave, desc in QUIMICA:
            f(cat, clave, desc)
    elif tipo == "auditorio":
        for cat, clave, desc in AUDITORIO:
            f(cat, clave, desc)
    elif tipo in ("sala_reuniones", "sala_de_reuniones"):
        for cat, clave, desc in REUNIONES:
            f(cat, clave, desc)
    else:  # aula
        indice = int(re.sub(r"\D", "", c))  # estable: el mismo salón siempre recibe lo mismo
        f("video_beam", "VB", "Video beam Epson PowerLite")
        f("otro", "TABLERO", "Tablero acrílico")
        if indice % 2 == 0:
            f("aire_ac", "AC", "Aire acondicionado 24000 BTU")
        else:
            f("otro", "VENT", "Ventiladores de techo (4)")
        if indice % 4 in (1, 2):
            f("audio", "AU", "Sonido básico (parlante y micrófono)")
    return filas


def _ajenos(db) -> set[tuple[int, str]]:
    """(salón, categoría) que YA tienen un equipo que no es DEMO-: ahí no se agrega otro igual
    (p. ej. los 30 computadores que ya cargó scripts/poblar_a1_piso4.py), salvo "otro"."""
    return {(sid, cat) for sid, cat in db.query(Recurso.salon_id, Recurso.categoria)
            .filter(~Recurso.serial.like(f"{PREFIJO}%"), Recurso.salon_id.isnot(None))}


def agregar(db, simular: bool, detalle: bool = False, confirmar: bool = True) -> dict:
    codigos = codigos_del_catalogo()
    salones = [s for s in db.query(Salon).order_by(Salon.nombre) if s.nombre in codigos]
    existentes = {r.serial for r in db.query(Recurso.serial).filter(Recurso.serial.like(f"{PREFIJO}%"))}
    ajenos = _ajenos(db)
    nuevos, por_categoria = 0, {}
    for salon in salones:
        resumen = []
        for cat, serial, desc in equipos_de(salon):
            if serial in existentes:
                continue
            if cat in ("computador", "video_beam", "aire_ac", "tv", "audio") and (salon.id, cat) in ajenos:
                continue  # ya tiene uno de ese tipo: no se duplica
            resumen.append((cat, serial, desc))
            estado, nota = NOVEDADES.get(serial, ("disponible", None))
            nuevos += 1
            por_categoria[cat] = por_categoria.get(cat, 0) + 1
            if not simular:
                db.add(Recurso(categoria=cat, serial=serial, estado=estado, salon_id=salon.id,
                               descripcion=f"{desc} · {nota}" if nota else desc))
        if detalle and resumen:
            pcs = sum(1 for c, *_ in resumen if c == "computador")
            otros = [d.split(" (")[0] for c, _, d in resumen if c != "computador"]
            marcas = [f"{NOVEDADES[sr][0]}!" for _, sr, _ in resumen if sr in NOVEDADES]
            print(f"  {salon.nombre} [{salon.tipo}]: " + (f"{pcs} computadores, " if pcs else "")
                  + ", ".join(otros) + (f"  ({'; '.join(marcas)})" if marcas else ""))
    deshabilitado = False
    codigo, motivo, nota = SALON_DESHABILITADO
    salon = next((s for s in salones if s.nombre == codigo), None)
    if salon is not None and salon.habilitado:
        deshabilitado = True
        if not simular:
            salon.habilitado = False
            salon.estado = "mantenimiento"
            salon.motivo_deshabilitado = motivo
            salon.nota_deshabilitado = nota
            salon.reapertura_estimada = date.today() + timedelta(days=5)
            admin = db.query(Usuario).filter(Usuario.rol == "administrador").first()
            db.add(HistorialSalon(salon_id=salon.id, accion="deshabilitado",
                                  actor_id=admin.id if admin else None,
                                  descripcion=f"Deshabilitado: Mantenimiento ({nota})"))
    if not simular and confirmar:
        db.commit()
    return {"salones": len(salones), "equipos_nuevos": nuevos, "por_categoria": por_categoria,
            "salon_deshabilitado": codigo if deshabilitado else None}


def quitar(db) -> int:
    """Quita SOLO los equipos DEMO-... que no tengan reportes ni mantenimientos."""
    from app.models import Reporte
    from app.models.recurso_models import MantenimientoRecurso
    from app.models.salon_models import ReporteSalon

    usados = {r for (r,) in db.query(Reporte.recurso_id)} | {
        r for (r,) in db.query(MantenimientoRecurso.recurso_id)} | {
        r for (r,) in db.query(ReporteSalon.recurso_id) if r}
    borrados = 0
    for r in db.query(Recurso).filter(Recurso.serial.like(f"{PREFIJO}%")):
        if r.id not in usados:
            db.delete(r)
            borrados += 1
    # Devuelve a su estado normal el salón que se deshabilitó para la demostración.
    codigo, motivo, nota = SALON_DESHABILITADO
    salon = db.query(Salon).filter(Salon.nombre == codigo).first()
    if salon is not None and not salon.habilitado and salon.nota_deshabilitado == nota:
        salon.habilitado, salon.estado = True, "disponible"
        salon.motivo_deshabilitado = salon.nota_deshabilitado = salon.reapertura_estimada = None
    db.commit()
    return borrados


def main() -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    args.add_argument("--produccion", action="store_true",
                      help="permite --quitar en el servidor (la carga en la nube es la migración)")
    args.add_argument("--simular", action="store_true", help="solo cuenta, no guarda")
    args.add_argument("--detalle", action="store_true", help="imprime lo que recibe cada salón")
    args.add_argument("--quitar", action="store_true", help="quita los equipos DEMO- sin reportes")
    opciones = args.parse_args()
    if config.ENVIRONMENT == "production" and not (opciones.quitar and opciones.produccion):
        print("En producción la carga es la migración de demostración; aquí solo se permite "
              "--quitar --produccion.")
        return 1
    db = SessionLocal()
    try:
        if opciones.quitar:
            print(f"Equipos DEMO quitados: {quitar(db)}")
            return 0
        r = agregar(db, opciones.simular, opciones.detalle)
        print(("Simulación: " if opciones.simular else "Listo: ")
              + f"{r['equipos_nuevos']} equipos nuevos en {r['salones']} salones del catálogo.")
        print("  por categoría:", r["por_categoria"])
        if r["salon_deshabilitado"]:
            print(f"  salón deshabilitado para la demo: {r['salon_deshabilitado']}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
