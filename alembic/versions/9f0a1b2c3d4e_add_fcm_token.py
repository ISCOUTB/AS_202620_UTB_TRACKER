"""add FCM token to users

Revision ID: 9f0a1b2c3d4e
Revises: 8e9f0a1b2c3d
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "9f0a1b2c3d4e"
down_revision: str | Sequence[str] | None = "8e9f0a1b2c3d"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("usuarios", sa.Column("fcm_token", sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column("usuarios", "fcm_token")
