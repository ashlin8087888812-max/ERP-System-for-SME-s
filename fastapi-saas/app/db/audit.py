"""
Audit logging helpers for tracking all mutations and actions.

Provides centralized audit trail with correlation IDs for request tracing.
"""
from sqlalchemy.orm import Session
from app.db import models
from typing import Optional, Dict, Any
import uuid


def write_audit(
    session: Session,
    actor_user_id: Optional[int],
    company_id: int,
    action: str,
    resource_type: str,
    resource_id: str,
    client_event_id: Optional[uuid.UUID],
    payload: Dict[str, Any],
    meta: Optional[Dict[str, Any]] = None
) -> models.AuditLog:
    """
    Create an audit log entry.
    
    Args:
        session: Database session
        actor_user_id: ID of user performing action (None for system actions)
        company_id: Tenant company ID
        action: Action type (e.g., "po.create", "grn.receive")
        resource_type: Type of resource (e.g., "purchase_order", "grn")
        resource_id: ID of the resource (global ID or Odoo ID)
        client_event_id: Client event ID for idempotency correlation
        payload: Action payload/data
        meta: Additional metadata (e.g., correlation_id, odoo_call)
    
    Returns:
        Created AuditLog instance
    """
    log = models.AuditLog(
        actor_user_id=actor_user_id,
        company_id=company_id,
        action=action,
        resource_type=resource_type,
        resource_id=str(resource_id),
        client_event_id=client_event_id,
        payload=payload,
        meta=meta or {}
    )
    session.add(log)
    session.commit()
    return log


def get_audit_trail(
    session: Session,
    company_id: int,
    resource_type: Optional[str] = None,
    resource_id: Optional[str] = None,
    limit: int = 100
) -> list[models.AuditLog]:
    """
    Retrieve audit trail for a company, optionally filtered by resource.
    
    Args:
        session: Database session
        company_id: Tenant company ID
        resource_type: Optional filter by resource type
        resource_id: Optional filter by resource ID
        limit: Maximum number of records to return
    
    Returns:
        List of AuditLog entries, ordered by created_at DESC
    """
    query = session.query(models.AuditLog).filter(
        models.AuditLog.company_id == company_id
    )
    
    if resource_type:
        query = query.filter(models.AuditLog.resource_type == resource_type)
    
    if resource_id:
        query = query.filter(models.AuditLog.resource_id == str(resource_id))
    
    return query.order_by(models.AuditLog.created_at.desc()).limit(limit).all()
