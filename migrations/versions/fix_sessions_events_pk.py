"""fix sessions and events primary key for ADK compatibility

Revision ID: fix_sessions_events_pk
Revises: add_name_language_users
Create Date: 2025-12-14 21:30:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "fix_sessions_events_pk"
down_revision: Union[str, None] = "add_name_language_users"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema.

    The Google ADK expects:
    - sessions table with composite PK (app_name, user_id, id)
    - events table with composite PK (id, app_name, user_id, session_id) and FK to sessions

    This migration drops existing tables and lets ADK recreate them with correct structure.
    """
    # Drop events table first (it has FK to sessions)
    op.execute("DROP TABLE IF EXISTS events CASCADE")

    # Drop sessions table
    op.execute("DROP TABLE IF EXISTS sessions CASCADE")


def downgrade() -> None:
    """Downgrade schema.

    Recreate the old sessions table structure (without events - ADK will recreate it)
    """
    op.create_table(
        'sessions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('app_name', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('state', sa.JSON(), nullable=True),
        sa.Column('create_time', sa.DateTime(timezone=True), nullable=True),
        sa.Column('update_time', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
