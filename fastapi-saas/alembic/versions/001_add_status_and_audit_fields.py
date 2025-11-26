"""
Database migration: Add status tracking to EventProcessed and update AuditLog

Revision ID: add_status_and_audit_fields
Revises: 
Create Date: 2025-11-20

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_status_and_audit_fields'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Update EventProcessed table
    op.add_column('events_processed', 
        sa.Column('status', sa.String(20), nullable=False, server_default='pending')
    )
    op.add_column('events_processed', 
        sa.Column('updated_at', sa.DateTime(), nullable=True)
    )
    op.alter_column('events_processed', 'event_type',
        existing_type=sa.Text(),
        type_=sa.String(50),
        nullable=False
    )
    
    # Update AuditLog table
    op.add_column('audit_logs',
        sa.Column('resource_type', sa.String(50), nullable=True)
    )
    op.add_column('audit_logs',
        sa.Column('resource_id', sa.String(100), nullable=True)
    )
    op.add_column('audit_logs',
        sa.Column('client_event_id', postgresql.UUID(as_uuid=True), nullable=True)
    )
    
    # Alter existing columns
    op.alter_column('audit_logs', 'action',
        existing_type=sa.Text(),
        type_=sa.String(100),
        nullable=False
    )
    op.alter_column('audit_logs', 'company_id',
        existing_type=sa.Integer(),
        nullable=False
    )
    
    # Add indexes for performance
    op.create_index('idx_audit_company', 'audit_logs', ['company_id'])
    op.create_index('idx_audit_actor', 'audit_logs', ['actor_user_id'])
    op.create_index('idx_audit_event', 'audit_logs', ['client_event_id'])
    op.create_index('idx_audit_created', 'audit_logs', ['created_at'])


def downgrade():
    # Remove indexes
    op.drop_index('idx_audit_created', 'audit_logs')
    op.drop_index('idx_audit_event', 'audit_logs')
    op.drop_index('idx_audit_actor', 'audit_logs')
    op.drop_index('idx_audit_company', 'audit_logs')
    
    # Revert AuditLog changes
    op.alter_column('audit_logs', 'company_id',
        existing_type=sa.Integer(),
        nullable=True
    )
    op.alter_column('audit_logs', 'action',
        existing_type=sa.String(100),
        type_=sa.Text(),
        nullable=False
    )
    op.drop_column('audit_logs', 'client_event_id')
    op.drop_column('audit_logs', 'resource_id')
    op.drop_column('audit_logs', 'resource_type')
    
    # Revert EventProcessed changes
    op.alter_column('events_processed', 'event_type',
        existing_type=sa.String(50),
        type_=sa.Text(),
        nullable=True
    )
    op.drop_column('events_processed', 'updated_at')
    op.drop_column('events_processed', 'status')
