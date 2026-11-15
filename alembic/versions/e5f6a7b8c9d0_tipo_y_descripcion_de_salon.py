"""tipo y descripción del salón (ADR-0017)

- salones.tipo: aula | laboratorio_computo | sala_audiovisual | auditorio | sala_reuniones |
  otro. server_default 'aula': los salones existentes quedan como aula.
- salones.descripcion: texto libre opcional (máx. 500).

El equipamiento NO se guarda: se calcula desde los recursos activos del salón.

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "e5f6a7b8c9d0"
down_revision: str | Sequence[str] | None = "d4e5f6a7b8c9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "salones",
        sa.Column("tipo", sa.String(30), nullable=False, server_default="aula"),
    )
    op.add_column("salones", sa.Column("descripcion", sa.String(500), nullable=True))
    op.create_index("ix_salones_tipo", "salones", ["tipo"])


def downgrade() -> None:
    op.drop_index("ix_salones_tipo", table_name="salones")
    with op.batch_alter_table("salones") as t:
        t.drop_column("descripcion")
        t.drop_column("tipo")
