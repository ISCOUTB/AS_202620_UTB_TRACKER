"""add resource maintenance orders and indexes

Revision ID: 8e9f0a1b2c3d
Revises: 7d1e2f3a4b5c
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "8e9f0a1b2c3d"
down_revision: str | Sequence[str] | None = "7d1e2f3a4b5c"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "mantenimientos_recursos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("recurso_id", sa.Integer(), nullable=False),
        sa.Column("reporte_id", sa.Integer(), nullable=True),
        sa.Column("tipo", sa.String(), nullable=False, server_default="correctivo"),
        sa.Column("estado", sa.String(), nullable=False, server_default="pendiente"),
        sa.Column("descripcion", sa.Text(), nullable=True),
        sa.Column("fecha_programada", sa.DateTime(), nullable=True),
        sa.Column("fecha_inicio", sa.DateTime(), nullable=True),
        sa.Column("fecha_fin", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["recurso_id"], ["recursos.id"]),
        sa.ForeignKeyConstraint(["reporte_id"], ["reportes.id"]),
    )
    op.create_index("ix_mantenimientos_recursos_id", "mantenimientos_recursos", ["id"])
    op.create_index("ix_mantenimientos_recursos_recurso_id", "mantenimientos_recursos", ["recurso_id"])
    op.create_index("ix_mantenimientos_recursos_reporte_id", "mantenimientos_recursos", ["reporte_id"])


def downgrade() -> None:
    op.drop_index("ix_mantenimientos_recursos_reporte_id", table_name="mantenimientos_recursos")
    op.drop_index("ix_mantenimientos_recursos_recurso_id", table_name="mantenimientos_recursos")
    op.drop_index("ix_mantenimientos_recursos_id", table_name="mantenimientos_recursos")
    op.drop_table("mantenimientos_recursos")
