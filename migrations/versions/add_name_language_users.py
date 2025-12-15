"""add name and language to users

Revision ID: add_name_language_users
Revises: 2df073c7b564
Create Date: 2025-12-14 10:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "add_name_language_users"
down_revision: Union[str, None] = "2df073c7b564"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add name column (nullable)
    op.add_column('users', sa.Column('name', sa.String(), nullable=True))

    # Add language column with default value
    op.add_column('users', sa.Column('language', sa.String(), nullable=False, server_default='en'))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove columns in reverse order
    op.drop_column('users', 'language')
    op.drop_column('users', 'name')
