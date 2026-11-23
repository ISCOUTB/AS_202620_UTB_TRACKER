"""foto de perfil en tabla aparte (ADR-0020)

- fotos_perfil: una fila por usuario con la miniatura ya limpia (sin EXIF/GPS), su tipo real,
  tamaño, dimensiones y una versión (clave de caché de la app).

Aditiva: tabla nueva; nadie tiene foto al desplegar y el servidor anterior la ignora.

Revision ID: b8c9d0e1f2a3
Revises: a7b8c9d0e1f2
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "b8c9d0e1f2a3"
down_revision: str | Sequence[str] | None = "a7b8c9d0e1f2"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "fotos_perfil",
        sa.Column("usuario_id", sa.Integer(),
                  sa.ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("contenido", sa.LargeBinary(), nullable=False),
        sa.Column("tipo", sa.String(20), nullable=False),
        sa.Column("tamano", sa.Integer(), nullable=False),
        sa.Column("ancho", sa.Integer(), nullable=False),
        sa.Column("alto", sa.Integer(), nullable=False),
        sa.Column("version", sa.BigInteger(), nullable=False),
        sa.Column("actualizado_en", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("fotos_perfil")
