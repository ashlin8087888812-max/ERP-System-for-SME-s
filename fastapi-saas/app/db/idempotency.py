"""
Idempotency helpers for event processing.

Implements event reservation pattern to prevent race conditions
and duplicate processing of client events.
"""
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.db import models
from typing import Optional
import uuid


def reserve_event(
    session: Session,
    client_event_id: uuid.UUID,
    company_id: int,
    user_id: Optional[int],
    event_type: str
) -> bool:
    """
    Reserve an event ID before enqueueing Celery task.
    
    Returns True if event was successfully reserved (new event).
    Returns False if event already exists and is not failed.
    
    This prevents race conditions where client retries before
    worker completes processing.
    """
    ep = models.EventProcessed(
        client_event_id=client_event_id,
        company_id=company_id,
        user_id=user_id,
        event_type=event_type,
        status="pending",
    )
    session.add(ep)
    
    try:
        session.commit()
        return True  # Successfully reserved
    except IntegrityError:
        session.rollback()
        # Event already exists, check its status
        existing = session.get(models.EventProcessed, client_event_id)
        
        if existing and existing.status == "failed":
            # Allow retry for failed events
            existing.status = "pending"
            session.commit()
            return True
        
        # Event is pending or processed, don't allow duplicate
        return False


def mark_processed(
    session: Session,
    client_event_id: uuid.UUID,
    result: dict
) -> None:
    """
    Mark an event as successfully processed.
    
    Updates status to 'processed' and stores result.
    """
    ep = session.get(models.EventProcessed, client_event_id)
    if ep:
        ep.status = "processed"
        ep.result = result
        session.commit()


def mark_failed(
    session: Session,
    client_event_id: uuid.UUID,
    error: str
) -> None:
    """
    Mark an event as failed.
    
    Updates status to 'failed' and stores error in result.
    """
    ep = session.get(models.EventProcessed, client_event_id)
    if ep:
        ep.status = "failed"
        ep.result = {"error": error}
        session.commit()


def get_event_status(
    session: Session,
    client_event_id: uuid.UUID
) -> Optional[dict]:
    """
    Get the status and result of an event.
    
    Returns dict with status and result, or None if not found.
    """
    ep = session.get(models.EventProcessed, client_event_id)
    if ep:
        return {
            "status": ep.status,
            "result": ep.result,
            "created_at": ep.created_at
        }
    return None
