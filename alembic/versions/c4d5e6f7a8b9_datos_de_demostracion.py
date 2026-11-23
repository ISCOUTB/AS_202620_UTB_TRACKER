"""datos de DEMOSTRACIÓN para la exposición: equipos, horarios, solicitudes, reportes y bitácora

Pedido por el dueño (2026-11-21): la presentación es el lunes 23 de noviembre de 2026 y la app
debe verse completa en la nube. Todo es FICTICIO y está marcado para limpiarlo después:
equipos con serial `DEMO-...`, horarios con semestre `2026-2 DEMO` y estudiantes
`estNN.demo@utb.edu.co` (de ellos cuelgan sus solicitudes, reportes y bitácora).

- NO crea salones (solo trabaja sobre los del catálogo, ADR-0021) y NO borra nada.
- Repetible: lo que ya existe se salta. Si no hay catálogo cargado, no hace nada.
- NO crea ninguna cuenta de Administrador con clave conocida (un administrador real se crea con
  scripts/crear_admin.py). Sí crea Estudiantes y un Auditor de demostración.
- Si algo falla, NO tumba el despliegue: se deshace solo esta carga y se avisa en el registro.
- Para no cargarla: variable de entorno CARGAR_DATOS_DEMO=0 al correr `alembic upgrade head`.
- Limpieza después de la exposición: docs/despliegue/demostracion.md.

Revision ID: c4d5e6f7a8b9
Revises: b3c4d5e6f7a8
"""
import logging
import os
import sys
from collections.abc import Sequence
from pathlib import Path

import sqlalchemy as sa
from alembic import op
from sqlalchemy.orm import Session

revision: str = "c4d5e6f7a8b9"
down_revision: str | Sequence[str] | None = "b3c4d5e6f7a8"
branch_labels = None
depends_on = None

logger = logging.getLogger("alembic.runtime.migration")
HORA_EXPOSICION = 10  # lunes 2026-11-23, 10:00 (hora de Colombia)


def upgrade() -> None:
    if os.getenv("CARGAR_DATOS_DEMO", "1").strip() == "0":
        logger.info("Datos de demostración: omitidos (CARGAR_DATOS_DEMO=0)")
        return
    bind = op.get_bind()
    if (bind.execute(sa.text("SELECT COUNT(*) FROM salones")).scalar() or 0) < 50:
        logger.info("Datos de demostración: omitidos (el catálogo de salones no está cargado)")
        return
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from scripts import cargar_demo_actividad, cargar_equipos_demo

    sesion = Session(bind=bind)
    try:
        with sesion.begin_nested():  # si algo falla se deshace SOLO esto
            equipos = cargar_equipos_demo.agregar(sesion, simular=False, confirmar=False)
            sesion.flush()
            actividad = cargar_demo_actividad.main_datos(sesion, HORA_EXPOSICION, con_admin=False)
            sesion.flush()
        logger.info("Datos de demostración cargados: %s | %s", equipos, actividad)
    except Exception:  # noqa: BLE001  (la demo nunca debe impedir un despliegue)
        logger.exception("Datos de demostración: NO se cargaron (el despliegue continúa)")


def downgrade() -> None:
    # No se deshace aquí: se retira con `scripts/cargar_demo_actividad.py --quitar --produccion`
    # y `scripts/cargar_equipos_demo.py --quitar --produccion` (docs/despliegue/demostracion.md).
    pass
