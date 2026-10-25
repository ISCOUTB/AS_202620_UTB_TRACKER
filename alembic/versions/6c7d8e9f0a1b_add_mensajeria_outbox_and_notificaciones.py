"""add_mensajeria_outbox_and_notificaciones

Revision ID: 6c7d8e9f0a1b
Revises: 5b652dd28f00
Create Date: 2026-10-24 22:40:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6c7d8e9f0a1b'
down_revision: Union[str, Sequence[str], None] = '5b652dd28f00'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'mensajes_outbox',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('message_id', sa.String(), nullable=False),
        sa.Column('tipo', sa.String(), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('payload', sa.Text(), nullable=False),
        sa.Column('correlation_id', sa.String(), nullable=True),
        sa.Column('estado', sa.String(), nullable=False, server_default='pendiente'),
        sa.Column('intentos', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('siguiente_intento', sa.DateTime(), nullable=False),
        sa.Column('ultimo_error', sa.Text(), nullable=True),
        sa.Column('creado_en', sa.DateTime(), nullable=False),
        sa.Column('procesado_en', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_mensajes_outbox_id'), 'mensajes_outbox', ['id'], unique=False)
    op.create_index(op.f('ix_mensajes_outbox_message_id'), 'mensajes_outbox', ['message_id'], unique=True)

    op.create_table(
        'notificaciones_procesadas',
        sa.Column('message_id', sa.String(), nullable=False),
        sa.Column('procesado_en', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('message_id')
    )
    op.create_index(op.f('ix_notificaciones_procesadas_message_id'), 'notificaciones_procesadas', ['message_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_notificaciones_procesadas_message_id'), table_name='notificaciones_procesadas')
    op.drop_table('notificaciones_procesadas')
    op.drop_index(op.f('ix_mensajes_outbox_message_id'), table_name='mensajes_outbox')
    op.drop_index(op.f('ix_mensajes_outbox_id'), table_name='mensajes_outbox')
    op.drop_table('mensajes_outbox')
