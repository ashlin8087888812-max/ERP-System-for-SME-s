"""remove odoo_host from company

Revision ID: 8ca004d0467a
Revises: 002_add_refresh_tokens
Create Date: 2026-03-23 19:15:45.184208

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
"""remove odoo_host from company

Revision ID: 8ca004d0467a
Revises: 002_add_refresh_tokens
Create Date: 2026-03-23 19:15:45.184208

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8ca004d0467a'
down_revision = '002_add_refresh_tokens'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column('companies', 'odoo_host')


def downgrade() -> None:
    op.add_column('companies', sa.Column('odoo_host', sa.String(), autoincrement=False, nullable=False))
