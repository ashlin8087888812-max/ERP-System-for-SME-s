from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db import models
from app.db.base import get_db
from app.api.deps import get_current_user
from app.odoo_client.client import odoo_client

router = APIRouter(tags=["accounting"])

def normalize_many2one(value):
    if not value or value is False:
        return None
    if isinstance(value, list) and len(value) == 2:
        return {"id": value[0], "name": value[1]}
    return None

class InvoiceOut(BaseModel):
    id: int
    name: Optional[str] = None
    partner_id: Optional[dict] = None
    invoice_date: Optional[str] = None
    amount_total: Optional[float] = None
    state: Optional[str] = None
    payment_state: Optional[str] = None
    move_type: Optional[str] = None

    class Config:
        from_attributes = True

def normalize_invoice(raw_data: dict) -> dict:
    normalized = {}
    for key, value in raw_data.items():
        if key in ['partner_id']:
            normalized[key] = normalize_many2one(value)
        else:
            normalized[key] = None if value is False else value
    return normalized

@router.get("/invoices", response_model=List[InvoiceOut])
def list_invoices(
    q: Optional[str] = Query(None, description="Search by name or customer"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    domain = [("move_type", "in", ("out_invoice", "in_invoice"))]
    if q:
        domain = [
            "&", ["move_type", "in", ("out_invoice", "in_invoice")],
            "|", ["name", "ilike", q],
            ["partner_id.name", "ilike", q]
        ]

    fields = ["id", "name", "partner_id", "invoice_date", "amount_total", "state", "payment_state", "move_type"]

    try:
        invoices = odoo_client.execute_kw(
            company,
            "account.move",
            "search_read",
            [domain],
            {"fields": fields, "limit": limit, "offset": offset, "order": "invoice_date DESC"}
        )
        return [normalize_invoice(inv) for inv in invoices]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

@router.get("/invoices/{invoice_id}", response_model=InvoiceOut)
def get_invoice(invoice_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    fields = ["id", "name", "partner_id", "invoice_date", "amount_total", "state", "payment_state", "move_type"]

    try:
        res = odoo_client.execute_kw(
            company,
            "account.move",
            "read",
            [[invoice_id]],
            {"fields": fields}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    if not res:
        raise HTTPException(status_code=404, detail="Invoice not found")

    return normalize_invoice(res[0])
