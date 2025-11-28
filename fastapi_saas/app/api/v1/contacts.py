# app/api/v1/contacts.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db import models
from app.db.session import get_db           # your DB dependency
from app.auth import get_current_user       # must return user with company_id
from app.odoo.client import odoo_client

router = APIRouter(prefix="/contacts", tags=["contacts"])


class ContactOut(BaseModel):
    id: int
    name: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    company_name: Optional[str]

    class Config:
        orm_mode = True


@router.get("/", response_model=List[ContactOut])
def list_contacts(
    q: Optional[str] = Query(None, description="search text"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List contacts from Odoo for the logged-in user's company.
    Uses odoo_client.execute_kw under the hood.
    """
    # find company row (or fail)
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")

    # Build domain search: is_company False (individual contacts)
    domain = [["is_company", "=", False]]
    if q:
        # search name, email, phone with OR
        domain = [
            "|", "|",
            ["name", "ilike", q],
            ["email", "ilike", q],
            ["phone", "ilike", q],
            ["is_company", "=", False]
        ]

    try:
        contacts = odoo_client.execute_kw(
            company,
            "res.partner",
            "search_read",
            [domain],
            {"fields": ["id", "name", "email", "phone", "company_name"], "limit": limit, "offset": offset}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    # Odoo returns list of dicts -> fastapi will coerce to ContactOut
    return contacts


@router.get("/{contact_id}", response_model=ContactOut)
def get_contact(contact_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")

    try:
        res = odoo_client.execute_kw(
            company,
            "res.partner",
            "read",
            [[contact_id]],
            {"fields": ["id", "name", "email", "phone", "company_name"]}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    if not res:
        raise HTTPException(status_code=404, detail="Contact not found")

    # read returns list of records
    return res[0]
