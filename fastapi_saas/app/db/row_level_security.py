"""
Row-Level Security (RLS) for PostgreSQL.

Provides database-level tenant isolation - even if application code has bugs,
tenants cannot access each other's data.
"""

# Migration: Enable Row-Level Security
RLS_MIGRATION = """
-- Enable RLS on all tenant-scoped tables

-- Purchase Orders
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_po ON purchase_orders
    USING (company_id = current_setting('app.current_company_id', true)::int);

-- Users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_users ON users
    USING (company_id = current_setting('app.current_company_id', true)::int);

-- Audit Logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_audit ON audit_logs
    USING (company_id = current_setting('app.current_company_id', true)::int);

-- Events Processed
ALTER TABLE events_processed ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_events ON events_processed
    USING (company_id = current_setting('app.current_company_id', true)::int);

-- Branches
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_branches ON branches
    USING (company_id = current_setting('app.current_company_id', true)::int);

-- User Roles (via user's company)
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_user_roles ON user_roles
    USING (
        user_id IN (
            SELECT id FROM users 
            WHERE company_id = current_setting('app.current_company_id', true)::int
        )
    );

-- Grant bypass to service accounts (for migrations, backups)
ALTER TABLE purchase_orders FORCE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;
"""


# Python helper to set tenant context
def set_tenant_context(db_session, company_id: int):
    """
    Set PostgreSQL session variable for RLS.
    
    This MUST be called at the start of every request that accesses tenant data.
    """
    db_session.execute(f"SET LOCAL app.current_company_id = {company_id}")


# Middleware integration
"""
Add to tenant_middleware.py:

async def tenant_middleware(request: Request, call_next):
    # ... existing code to get tenant ...
    
    # Set RLS context
    db = SessionLocal()
    try:
        set_tenant_context(db, tenant['company_id'])
        request.state.db = db
        response = await call_next(request)
    finally:
        db.close()
    
    return response
"""
