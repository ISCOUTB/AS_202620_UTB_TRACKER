"""add presencias_salon y reportes_salon

Revision ID: 7d1e2f3a4b5c
Revises: 4b78d656413b
Create Date: 2026-10-25 20:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7d1e2f3a4b5c'
down_revision: Union[str, Sequence[str], None] = '4b78d656413b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'presencias_salon',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('salon_id', sa.Integer(), nullable=False),
        sa.Column('horario_id', sa.Integer(), nullable=False),
        sa.Column('fecha', sa.Date(), nullable=False),
        sa.Column('profesor_presente', sa.Boolean(), nullable=False),
        sa.Column('nota', sa.String(), nullable=True),
        sa.Column('registrado_por', sa.Integer(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['salon_id'], ['salones.id']),
        sa.ForeignKeyConstraint(['horario_id'], ['horarios.id']),
        sa.ForeignKeyConstraint(['registrado_por'], ['usuarios.id']),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('horario_id', 'fecha', name='uq_presencia_horario_fecha'),
    )
    op.create_index(op.f('ix_presencias_salon_id'), 'presencias_salon', ['id'], unique=False)
    op.create_index(op.f('ix_presencias_salon_salon_id'), 'presencias_salon', ['salon_id'], unique=False)

    op.create_table(
        'reportes_salon',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('salon_id', sa.Integer(), nullable=False),
        sa.Column('usuario_id', sa.Integer(), nullable=False),
        sa.Column('tipo', sa.String(), nullable=False),
        sa.Column('descripcion', sa.String(), nullable=False),
        sa.Column('estado', sa.String(), nullable=False, server_default='abierto'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('resuelto_en', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['salon_id'], ['salones.id']),
        sa.ForeignKeyConstraint(['usuario_id'], ['usuarios.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_reportes_salon_id'), 'reportes_salon', ['id'], unique=False)
    op.create_index(op.f('ix_reportes_salon_salon_id'), 'reportes_salon', ['salon_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_reportes_salon_salon_id'), table_name='reportes_salon')
    op.drop_index(op.f('ix_reportes_salon_id'), table_name='reportes_salon')
    op.drop_table('reportes_salon')
    op.drop_index(op.f('ix_presencias_salon_salon_id'), table_name='presencias_salon')
    op.drop_index(op.f('ix_presencias_salon_id'), table_name='presencias_salon')
    op.drop_table('presencias_salon')
