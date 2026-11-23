"""add auditoria (bitácora de solo-agregar)

Revision ID: a1b2c3d4e5f6
Revises: 9f0a1b2c3d4e
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "a1b2c3d4e5f6"
down_revision: str | Sequence[str] | None = "9f0a1b2c3d4e"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "auditoria",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ocurrio_en", sa.DateTime(), nullable=False),
        sa.Column("actor_id", sa.Integer(), nullable=True),
        sa.Column("actor_nombre", sa.String(), nullable=True),
        sa.Column("accion", sa.String(), nullable=False),
        sa.Column("entidad", sa.String(), nullable=False),
        sa.Column("entidad_id", sa.Integer(), nullable=True),
        sa.Column("detalle", sa.Text(), nullable=True),
        sa.Column("request_id", sa.String(), nullable=True),
        sa.ForeignKeyConstraint(["actor_id"], ["usuarios.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_auditoria_id"), "auditoria", ["id"], unique=False)
    op.create_index(op.f("ix_auditoria_ocurrio_en"), "auditoria", ["ocurrio_en"], unique=False)
    op.create_index(op.f("ix_auditoria_actor_id"), "auditoria", ["actor_id"], unique=False)
    op.create_index(op.f("ix_auditoria_accion"), "auditoria", ["accion"], unique=False)
    op.create_index(op.f("ix_auditoria_entidad"), "auditoria", ["entidad"], unique=False)

    # En PostgreSQL la bitácora se protege también a nivel de base de datos: ni UPDATE ni DELETE.
    if op.get_bind().dialect.name == "postgresql":
        op.execute(
            """
            CREATE FUNCTION auditoria_solo_agregar() RETURNS trigger AS $$
            BEGIN
                RAISE EXCEPTION 'La tabla auditoria es de solo-agregar';
            END;
            $$ LANGUAGE plpgsql
            """
        )
        op.execute(
            """
            CREATE TRIGGER auditoria_inmutable BEFORE UPDATE OR DELETE ON auditoria
            FOR EACH ROW EXECUTE FUNCTION auditoria_solo_agregar()
            """
        )


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        op.execute("DROP TRIGGER IF EXISTS auditoria_inmutable ON auditoria")
        op.execute("DROP FUNCTION IF EXISTS auditoria_solo_agregar()")
    op.drop_index(op.f("ix_auditoria_entidad"), table_name="auditoria")
    op.drop_index(op.f("ix_auditoria_accion"), table_name="auditoria")
    op.drop_index(op.f("ix_auditoria_actor_id"), table_name="auditoria")
    op.drop_index(op.f("ix_auditoria_ocurrio_en"), table_name="auditoria")
    op.drop_index(op.f("ix_auditoria_id"), table_name="auditoria")
    op.drop_table("auditoria")
