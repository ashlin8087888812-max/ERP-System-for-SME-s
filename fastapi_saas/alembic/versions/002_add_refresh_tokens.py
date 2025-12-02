"""
Add refresh_tokens table for enterprise-grade stateful authentication

Revision ID: 002_add_refresh_tokens
Revises: add_status_and_audit_fields
Create Date: 2025-12-02

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '002_add_refresh_tokens'
down_revision = 'add_status_and_audit_fields'
branch_labels = None
depends_on = None


def upgrade():
    """
    Create refresh_tokens table for stateful refresh token storage.
    
    Stores hashed tokens (not raw) for security.
    Includes comprehensive indexes for performance.
    """
    op.create_table(
        'refresh_tokens',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('token_hash', sa.String(255), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('revoked', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('revoked_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('last_used_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        
        # Optional metadata for security auditing
        sa.Column('device_fingerprint', sa.String(255), nullable=True),
        sa.Column('ip_address', sa.String(45), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        
        # Constraints
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('token_hash', name='uq_refresh_token_hash')
    )
    
    # Indexes for performance
    op.create_index('idx_refresh_token_user', 'refresh_tokens', ['user_id'])
    op.create_index('idx_refresh_token_hash', 'refresh_tokens', ['token_hash'])
    op.create_index('idx_refresh_token_expires', 'refresh_tokens', ['expires_at'])
    op.create_index('idx_refresh_token_revoked', 'refresh_tokens', ['revoked'])
    
    # Composite index for common query: find valid tokens for user
    op.create_index(
        'idx_refresh_token_user_valid',
        'refresh_tokens',
        ['user_id', 'revoked', 'expires_at']
    )


def downgrade():
    """
    Drop refresh_tokens table and all associated indexes.
    """
    op.drop_index('idx_refresh_token_user_valid', 'refresh_tokens')
    op.drop_index('idx_refresh_token_revoked', 'refresh_tokens')
    op.drop_index('idx_refresh_token_expires', 'refresh_tokens')
    op.drop_index('idx_refresh_token_hash', 'refresh_tokens')
    op.drop_index('idx_refresh_token_user', 'refresh_tokens')
    op.drop_table('refresh_tokens')
