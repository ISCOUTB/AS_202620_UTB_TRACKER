"""cargar el catálogo provisional de salones UTB (ADR-0021)

Pedido por el dueño del proyecto el 2026-11-16: los estudiantes deben ver los salones en la nube
sin pasos manuales. Lee scripts/datos/catalogo_utb.json (59 salones, PROVISIONAL) y crea SOLO
los que faltan. Nunca borra ni modifica salones existentes. Idempotente.

Revision ID: f2a3b4c5d6e7
Revises: e1f2a3b4c5d6
"""
import json
from collections.abc import Sequence
from pathlib import Path

import sqlalchemy as sa
from alembic import op

revision: str = "f2a3b4c5d6e7"
down_revision: str | Sequence[str] | None = "e1f2a3b4c5d6"
branch_labels = None
depends_on = None

ARCHIVO = Path(__file__).resolve().parents[2] / "scripts" / "datos" / "catalogo_utb.json"


def upgrade() -> None:
    datos = json.loads(ARCHIVO.read_text(encoding="utf-8"))
    tipos = {k: v for k, v in datos.get("tipos", {}).items() if not k.startswith("_")}
    capacidad = int(datos.get("capacidad_por_defecto", 40))
    con = op.get_bind()
    existentes = {n for (n,) in con.execute(sa.text("SELECT nombre FROM salones"))}
    creados = 0
    for r in datos["rangos"]:
        desde = int(r["desde"])
        hasta = int(r["hasta"])
        for n in range(desde, min(hasta + 1, desde + 100)):
            codigo = f"A{r['edificio']}-{r['piso']}{n:02d}"
            if codigo in existentes:
                continue
            edificio = f"A{r['edificio']}"
            con.execute(sa.text(
                "INSERT INTO salones (nombre, ubicacion, edificio, piso, capacidad,"
                " capacidad_estimada, tipo, estado, activo, habilitado, created_at, updated_at)"
                " VALUES (:n, :u, :e, :p, :c, :ce, :t, 'disponible', :a, :h,"
                " CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            ), {"n": codigo, "u": f"Edificio {edificio}, piso {r['piso']}", "e": edificio,
                "p": r["piso"], "c": capacidad, "ce": True, "t": tipos.get(codigo, "aula"),
                "a": True, "h": True})
            creados += 1
    if creados:
        con.execute(sa.text(
            "INSERT INTO auditoria (ocurrio_en, actor_nombre, accion, entidad, detalle)"
            " VALUES (CURRENT_TIMESTAMP, 'migración f2a3b4c5d6e7', 'salon.catalogo.cargar',"
            " 'salon', :d)"), {"d": json.dumps({"creados": creados})})


def downgrade() -> None:
    # No se revierte la carga automática de catálogo para preservar los salones creados.
    pass
