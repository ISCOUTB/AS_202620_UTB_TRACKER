"""habilitación del salón separada de la ocupación, historial y vínculo reporte-equipo (ADR-0022)

- salones.habilitado (true por defecto), motivo_deshabilitado, nota_deshabilitado,
  reapertura_estimada.
- historial_salon: cambios legibles de estado del salón y de sus equipos.
- reportes_salon.recurso_id: equipo al que se refiere un reporte de tipo "equipo" (opcional).

Datos existentes (no se borra nada ni se cambian valores guardados de `estado`):
- estado = 'mantenimiento'  -> habilitado = false, motivo 'mantenimiento'
- estado = 'fuera_servicio' -> habilitado = false, motivo 'danio'
- estado = 'ocupado' (ya no se guarda: se calcula) se deja tal cual; cuenta como habilitado.

Aditiva y con server_default: el servidor anterior sigue funcionando durante el despliegue.

Revision ID: d0e1f2a3b4c5
Revises: c9d0e1f2a3b4
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "d0e1f2a3b4c5"
down_revision: str | Sequence[str] | None = "c9d0e1f2a3b4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("salones") as batch:
        batch.add_column(sa.Column("habilitado", sa.Boolean(), nullable=False,
                                   server_default=sa.true()))
        batch.add_column(sa.Column("motivo_deshabilitado", sa.String(20), nullable=True))
        batch.add_column(sa.Column("nota_deshabilitado", sa.String(300), nullable=True))
        batch.add_column(sa.Column("reapertura_estimada", sa.Date(), nullable=True))
    op.execute(
        "UPDATE salones SET habilitado = false, motivo_deshabilitado = 'mantenimiento' "
        "WHERE estado = 'mantenimiento'"
    )
    op.execute(
        "UPDATE salones SET habilitado = false, motivo_deshabilitado = 'danio' "
        "WHERE estado = 'fuera_servicio'"
    )
    op.create_table(
        "historial_salon",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("salon_id", sa.Integer(), sa.ForeignKey("salones.id"), nullable=False),
        sa.Column("accion", sa.String(30), nullable=False),
        sa.Column("descripcion", sa.String(500), nullable=False),
        sa.Column("actor_id", sa.Integer(), sa.ForeignKey("usuarios.id"), nullable=True),
        sa.Column("creado_en", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_historial_salon_id", "historial_salon", ["id"])
    op.create_index("ix_historial_salon_salon_id", "historial_salon", ["salon_id"])
    with op.batch_alter_table("reportes_salon") as batch:
        batch.add_column(sa.Column("recurso_id", sa.Integer(), nullable=True))
        batch.create_foreign_key("fk_reportes_salon_recurso", "recursos", ["recurso_id"], ["id"])


def downgrade() -> None:
    with op.batch_alter_table("reportes_salon") as batch:
        batch.drop_constraint("fk_reportes_salon_recurso", type_="foreignkey")
        batch.drop_column("recurso_id")
    op.drop_index("ix_historial_salon_salon_id", table_name="historial_salon")
    op.drop_index("ix_historial_salon_id", table_name="historial_salon")
    op.drop_table("historial_salon")
    with op.batch_alter_table("salones") as batch:
        batch.drop_column("reapertura_estimada")
        batch.drop_column("nota_deshabilitado")
        batch.drop_column("motivo_deshabilitado")
        batch.drop_column("habilitado")
