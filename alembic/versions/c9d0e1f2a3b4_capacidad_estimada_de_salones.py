"""capacidad estimada de los salones del catálogo UTB (ADR-0021)

- salones.capacidad_estimada: True cuando la capacidad es un valor por defecto sin dato oficial
  (los salones del catálogo provisional nacen así). Los salones existentes quedan en False
  (su capacidad la escribió alguien a mano).

Aditiva y con server_default: el servidor anterior sigue funcionando durante el despliegue.

Revision ID: c9d0e1f2a3b4
Revises: b8c9d0e1f2a3
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "c9d0e1f2a3b4"
down_revision: str | Sequence[str] | None = "b8c9d0e1f2a3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("salones") as batch:
        batch.add_column(sa.Column("capacidad_estimada", sa.Boolean(), nullable=False,
                                   server_default=sa.false()))


def downgrade() -> None:
    with op.batch_alter_table("salones") as batch:
        batch.drop_column("capacidad_estimada")
