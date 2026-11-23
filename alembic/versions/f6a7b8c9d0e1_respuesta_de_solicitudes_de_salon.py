"""respuesta del auditor a las solicitudes de salón (ADR-0018)

- prestamos_salon.respuesta: motivo del rechazo o nota al aprobar (opcional, máx. 500).
- prestamos_salon.atendido_por_id: quién la aprobó o rechazó (NULL en las anteriores).
- prestamos_salon.atendido_en: cuándo (UTC naive, como las fechas de préstamo).

Todas las columnas son opcionales: las solicitudes existentes quedan igual y la versión
anterior del servidor sigue funcionando durante el despliegue. Los roles guardados en
`usuarios.rol` NO cambian (las etiquetas Estudiante/Auditor/Administrador se calculan).

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "f6a7b8c9d0e1"
down_revision: str | Sequence[str] | None = "e5f6a7b8c9d0"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("prestamos_salon", sa.Column("respuesta", sa.String(500), nullable=True))
    # Sin restricción de clave foránea en la base: SQLite no la permite con ALTER TABLE y el
    # modo batch reconstruiría la tabla. La relación con usuarios la declara el modelo ORM.
    op.add_column("prestamos_salon", sa.Column("atendido_por_id", sa.Integer, nullable=True))
    op.add_column("prestamos_salon", sa.Column("atendido_en", sa.DateTime, nullable=True))
    op.create_index("ix_prestamos_salon_estado", "prestamos_salon", ["estado"])


def downgrade() -> None:
    op.drop_index("ix_prestamos_salon_estado", table_name="prestamos_salon")
    with op.batch_alter_table("prestamos_salon") as t:
        t.drop_column("atendido_en")
        t.drop_column("atendido_por_id")
        t.drop_column("respuesta")
