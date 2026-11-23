"""desactivar las cuentas con correo de un dominio no permitido (ADR-0024)

Decisión del dueño (2026-11-21): solo el dominio institucional (DOMINIOS_PERMITIDOS, por defecto
utb.edu.co) puede usar la app. Las cuentas que ya existían con otro dominio se DESACTIVAN y se
les cierran las sesiones; NO se borra nada (un administrador puede reactivarlas).

Protección: un administrador activo con otro dominio NO se toca, para no dejar el sistema sin
administrador (hay que migrarlo a mano a un correo institucional).
No cambia el esquema. La retirada de las columnas de verificación irá en una migración posterior.

Revision ID: b3c4d5e6f7a8
Revises: f2a3b4c5d6e7
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

from app.config import config

revision: str = "b3c4d5e6f7a8"
down_revision: str | Sequence[str] | None = "f2a3b4c5d6e7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    con = op.get_bind()
    filas = con.execute(sa.text(
        "SELECT id, email FROM usuarios WHERE activo = :si AND rol <> 'administrador'"
    ), {"si": True}).fetchall()
    ids = [
        fila.id for fila in filas
        if (fila.email or "").strip().lower().rpartition("@")[2] not in config.DOMINIOS_PERMITIDOS
    ]
    for uid in ids:
        con.execute(sa.text(
            "UPDATE usuarios SET activo = :no, sesion_version = COALESCE(sesion_version, 0) + 1 "
            "WHERE id = :id"), {"no": False, "id": uid})


def downgrade() -> None:
    # Irreversible a propósito: no sabemos cuáles estaban activas antes. Un administrador
    # puede reactivar cuentas desde la pantalla Usuarios.
    pass
