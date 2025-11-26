from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel, UUID4
from typing import List, Optional, Dict, Any
from app.db import models
from app.db.base import get_db
from app.api import deps
from app.middleware.tenant import require_tenant
from app.db.idempotency import reserve_event, get_event_status
from app.workers.celery_app import persist_po_to_odoo, persist_grn_to_odoo
import uuid

router = APIRouter()

class PurchaseOrderLine(BaseModel):
    sku: str
    qty: float
    price_unit: Optional[float] = None

class PurchaseOrderCreate(BaseModel):
    client_event_id: UUID4
    po_ref: str
    items: List[PurchaseOrderLine]
    vendor_id: Optional[int] = None

class GRNCreate(BaseModel):
    client_event_id: UUID4
    po_ref: str
    items: List[Dict[str, Any]]


@router.post("/purchase-orders", status_code=status.HTTP_202_ACCEPTED)
def create_purchase_order(
    request: Request,
    po_in: PurchaseOrderCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    tenant: dict = Depends(require_tenant)
):
    """
    Create Purchase Order with idempotency and tenant context.
    
    Uses reserve_event pattern to prevent race conditions.
    """
    # Reserve event BEFORE enqueueing task
    if not reserve_event(
        db,
        po_in.client_event_id,
        tenant["company_id"],
        current_user.id,
        "po.create"
    ):
        # Event already exists, return existing status
        existing = get_event_status(db, po_in.client_event_id)
        return {
            "status": existing["status"],
            "client_event_id": str(po_in.client_event_id),
            "result": existing.get("result")
        }
    
    # Enqueue Celery task with tenant parameter
    task = persist_po_to_odoo.delay(
        str(po_in.client_event_id),
        tenant,  # Pass entire tenant context
        current_user.id,
        po_in.dict(exclude={"client_event_id"})
    )
    
    return {
        "status": "pending",
        "task_id": str(task.id),
        "client_event_id": str(po_in.client_event_id),
        "correlation_id": request.state.correlation_id
    }


@router.post("/grn", status_code=status.HTTP_202_ACCEPTED)
def create_grn(
    request: Request,
    grn_in: GRNCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    tenant: dict = Depends(require_tenant)
):
    """
    Create GRN (Goods Receipt Note) with idempotency.
    """
    # Reserve event
    if not reserve_event(
        db,
        grn_in.client_event_id,
        tenant["company_id"],
        current_user.id,
        "grn.receive"
    ):
        existing = get_event_status(db, grn_in.client_event_id)
        return {
            "status": existing["status"],
            "client_event_id": str(grn_in.client_event_id),
            "result": existing.get("result")
        }
    
    # Enqueue task with tenant
    task = persist_grn_to_odoo.delay(
        str(grn_in.client_event_id),
        tenant,
        current_user.id,
        grn_in.dict(exclude={"client_event_id"})
    )
    
    return {
        "status": "pending",
        "task_id": str(task.id),
        "client_event_id": str(grn_in.client_event_id),
        "correlation_id": request.state.correlation_id
    }
