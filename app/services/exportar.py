"""
Exportación del catálogo de salones y sus equipos a CSV (ADR-0022), para revisarlo con
Planta Física. Dos consultas en total. Sin datos personales.
"""
import csv
import io

from sqlalchemy.orm import Session

from app.models.salon_models import Salon
from app.services import catalogo, equipamiento

COLUMNAS = [
    "codigo", "edificio", "piso", "ubicacion", "tipo", "capacidad", "capacidad_estimada",
    "habilitado", "motivo_deshabilitado", "reapertura_estimada", "equipos_total",
    "equipos_operativos", "detalle_equipos",
]


def _celda(valor) -> str:
    """Evita inyección de fórmulas al abrir el CSV en una hoja de cálculo."""
    texto = "" if valor is None else str(valor)
    return "'" + texto if texto[:1] in ("=", "+", "-", "@") else texto


def catalogo_csv(db: Session) -> str:
    salones = sorted(db.query(Salon).filter(Salon.activo.is_(True)).all(),
                     key=lambda s: catalogo.clave_orden(s.nombre))
    por_salon = equipamiento.calcular(db, [s.id for s in salones])
    salida = io.StringIO()
    escritor = csv.writer(salida)
    escritor.writerow(COLUMNAS)
    for s in salones:
        eq = por_salon.get(s.id, [])
        escritor.writerow([_celda(v) for v in (
            s.nombre, s.edificio, s.piso, s.ubicacion, s.tipo, s.capacidad,
            "sí" if s.capacidad_estimada else "no", "sí" if s.habilitado else "no",
            s.motivo_deshabilitado, s.reapertura_estimada,
            sum(e["total"] for e in eq), sum(e["operativos"] for e in eq),
            "; ".join(f"{e['categoria']} {e['operativos']}/{e['total']}" for e in eq),
        )])
    return "﻿" + salida.getvalue()  # BOM: Excel abre bien las tildes


