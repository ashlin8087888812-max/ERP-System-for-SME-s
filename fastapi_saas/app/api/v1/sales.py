from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db import models
from app.db.base import get_db
from app.api.deps import get_current_user
from app.odoo_client.client import odoo_client

router = APIRouter(tags=["sales"])

def normalize_many2one(value):
    if not value or value is False:
        return None
    if isinstance(value, list) and len(value) == 2:
        return {"id": value[0], "name": value[1]}
    return None

class SaleOrderOut(BaseModel):
    id: int
    name: Optional[str] = None
    partner_id: Optional[dict] = None
    date_order: Optional[str] = None
    amount_total: Optional[float] = None
    state: Optional[str] = None
    invoice_status: Optional[str] = None

    class Config:
        from_attributes = True

def normalize_sale_order(raw_data: dict) -> dict:
    normalized = {}
    for key, value in raw_data.items():
        if key in ['partner_id']:
            normalized[key] = normalize_many2one(value)
        else:
            normalized[key] = None if value is False else value
    return normalized

@router.get("/", response_model=List[SaleOrderOut])
def list_sales_orders(
    q: Optional[str] = Query(None, description="Search by name or customer"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    domain = []
    if q:
        domain = [
            "|", ["name", "ilike", q],
            ["partner_id.name", "ilike", q]
        ]

    fields = ["id", "name", "partner_id", "date_order", "amount_total", "state", "invoice_status"]

    try:
        sales = odoo_client.execute_kw(
            company,
            "sale.order",
            "search_read",
            [domain],
            {"fields": fields, "limit": limit, "offset": offset, "order": "date_order DESC"}
        )
        return [normalize_sale_order(s) for s in sales]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

@router.get("/{sale_id}", response_model=SaleOrderOut)
def get_sale_order(sale_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    fields = ["id", "name", "partner_id", "date_order", "amount_total", "state", "invoice_status"]

    try:
        res = odoo_client.execute_kw(
            company,
            "sale.order",
            "read",
            [[sale_id]],
            {"fields": fields}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    if not res:
        raise HTTPException(status_code=404, detail="Sale order not found")

    return normalize_sale_order(res[0])
