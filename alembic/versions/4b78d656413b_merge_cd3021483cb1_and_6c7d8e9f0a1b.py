"""merge cd3021483cb1 and 6c7d8e9f0a1b

Revision ID: 4b78d656413b
Revises: 6c7d8e9f0a1b, cd3021483cb1
Create Date: 2026-10-25 13:28:47.233703

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4b78d656413b'
down_revision: Union[str, Sequence[str], None] = ('6c7d8e9f0a1b', 'cd3021483cb1')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
