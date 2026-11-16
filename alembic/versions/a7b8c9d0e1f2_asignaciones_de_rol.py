"""rol asignado por correo institucional verificado (ADR-0019)

- asignaciones_rol: lista que mantiene el administrador (correo exacto -> rol, cargo opcional).
- usuarios.rol_manual: True cuando el rol lo puso un administrador; la regla automática no lo
  pisa. TODAS las cuentas que ya tenían un rol alto (auditor o administrador) quedan con
  rol_manual = True: nadie pierde su rol por esta migración.

Aditiva: la tabla es nueva y la columna tiene server_default, así que el servidor anterior
sigue funcionando durante el despliegue. Los valores guardados de `usuarios.rol` NO cambian.

Revision ID: a7b8c9d0e1f2
Revises: f6a7b8c9d0e1
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "a7b8c9d0e1f2"
down_revision: str | Sequence[str] | None = "f6a7b8c9d0e1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("usuarios", sa.Column("rol_manual", sa.Boolean(), nullable=False,
                                        server_default=sa.false()))
    op.execute(
        sa.text("UPDATE usuarios SET rol_manual = :si WHERE lower(rol) <> 'usuario_utb'")
        .bindparams(si=True)
    )
    op.create_table(
        "asignaciones_rol",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("correo", sa.String(254), nullable=False, unique=True),
        sa.Column("rol", sa.String(20), nullable=False),
        sa.Column("cargo", sa.String(120), nullable=True),
        sa.Column("creado_por_id", sa.Integer(), sa.ForeignKey("usuarios.id"), nullable=True),
        sa.Column("creado_en", sa.DateTime(), nullable=False),
        sa.Column("actualizado_en", sa.DateTime(), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("asignaciones_rol")
    with op.batch_alter_table("usuarios") as t:
        t.drop_column("rol_manual")
