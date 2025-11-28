from sqlalchemy.orm import Session
from app.db import models
from uuid import UUID
from typing import Optional, Dict, Any
import json

def check_idempotency(db: Session, client_event_id: UUID) -> Optional[Dict[str, Any]]:
    event = db.query(models.EventProcessed).filter(models.EventProcessed.client_event_id == client_event_id).first()
    if event:
        return event.result
    return None

def mark_processed(db: Session, client_event_id: UUID, company_id: int, user_id: int, event_type: str, result: Dict[str, Any]):
    event = models.EventProcessed(
        client_event_id=client_event_id,
        company_id=company_id,
        user_id=user_id,
        event_type=event_type,
        result=result
    )
    db.add(event)
    db.commit()
