"""perfil personalizable, preferencias en el servidor y versión de sesión (ADR-0016)

- nombre_mostrar, telefono, dependencia (dependencia o cargo), color_avatar: opcionales.
- preferencias (JSON): notificaciones por canal y tipo, tamaño de texto, pantalla de inicio.
  NULL = valores por defecto (ver app/schemas/perfil.py).
- sesion_version: sube al cambiar la contraseña o cerrar todas las sesiones; los tokens con una
  versión menor dejan de valer (ADR-0014).

Se usa ADD COLUMN directo (no batch) para no perder en SQLite el índice por expresión
uq_usuarios_email_lower.

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "d4e5f6a7b8c9"
down_revision: str | Sequence[str] | None = "c3d4e5f6a7b8"
branch_labels = None
depends_on = None

_COLUMNAS = ("nombre_mostrar", "telefono", "dependencia", "color_avatar", "preferencias",
             "sesion_version")


def upgrade() -> None:
    op.add_column("usuarios", sa.Column("nombre_mostrar", sa.String(100), nullable=True))
    op.add_column("usuarios", sa.Column("telefono", sa.String(30), nullable=True))
    op.add_column("usuarios", sa.Column("dependencia", sa.String(120), nullable=True))
    op.add_column("usuarios", sa.Column("color_avatar", sa.String(9), nullable=True))
    op.add_column("usuarios", sa.Column("preferencias", sa.JSON(), nullable=True))
    op.add_column(
        "usuarios",
        sa.Column("sesion_version", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    with op.batch_alter_table("usuarios") as t:
        for columna in reversed(_COLUMNAS):
            t.drop_column(columna)
    if op.get_bind().dialect.name == "sqlite":
        op.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_usuarios_email_lower ON usuarios (lower(email))")
