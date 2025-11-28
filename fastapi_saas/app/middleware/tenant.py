from fastapi import Request, HTTPException, status
from typing import Optional
from app.db.base import SessionLocal
from app.db import models

async def tenant_middleware(request: Request, call_next):
    """
    Multi-tenant middleware that injects tenant context into request.state
    
    Extracts company_id from JWT token (set by auth dependency)
    and fetches company details (db_name, odoo_host) from database.
    """
    # Get user from request.state (set by JWT auth dependency)
    user = getattr(request.state, "user", None)
    
    if user and hasattr(user, 'company_id'):
        # Create DB session
        db = SessionLocal()
        try:
            # Fetch company details
            company = db.query(models.Company).filter(
                models.Company.id == user.company_id
            ).first()
            
            if company:
                # Inject tenant context into request
                request.state.tenant = {
                    "company_id": company.id,
                    "db_name": company.db_name,
                    "odoo_host": company.odoo_host,
                    "company_name": company.name
                }
            else:
                # Company not found
                request.state.tenant = None
        finally:
            db.close()
    else:
        # No authenticated user or no company_id
        request.state.tenant = None
    
    response = await call_next(request)
    return response


def get_tenant(request: Request) -> Optional[dict]:
    """
    Helper to get tenant context from request.
    Returns None if no tenant context available.
    """
    return getattr(request.state, "tenant", None)


def require_tenant(request: Request) -> dict:
    """
    Dependency that requires tenant context to be present.
    Raises 403 if no tenant context.
    """
    tenant = get_tenant(request)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tenant context required"
        )
    return tenant
