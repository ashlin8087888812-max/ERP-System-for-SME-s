# app/api/v1/contacts.py
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from typing import List, Optional, Union, Dict
from pydantic import BaseModel, field_validator, ValidationInfo, Field
from sqlalchemy.orm import Session
from app.db import models
from app.db.base import get_db
from app.api.deps import get_current_user
from app.odoo_client.client import odoo_client
from app.core.logging import logger


# ==================== Normalization Utilities ====================

def normalize_odoo_false(value):
    """Convert Odoo False to None for data fields (not boolean flags)"""
    return None if value is False else value


def normalize_bool(value):
    """
    Convert Odoo boolean values.
    Odoo False → Python False
    Odoo True/any truthy → Python True
    """
    return False if value is False else bool(value)


def normalize_many2one(value):
    """Convert Odoo Many2one [id, name] to {"id": int, "name": str}"""
    if not value or value is False:
        return None
    if isinstance(value, list) and len(value) == 2:
        return {"id": value[0], "name": value[1]}
    return None


def normalize_many2many(value):
    """
    Convert Odoo Many2many IDs to [{"id": int}]
    
    Note: Only IDs are returned. Names require additional Odoo calls.
    Future enhancement: batch fetch names for common fields.
    """
    if not value or value is False:
        return []
    # Return IDs only for now
    return [{"id": id_val} for id_val in value]


def normalize_contact(raw_data: dict) -> dict:
    """Normalize all Odoo fields in a contact record"""
    normalized = {}
    for key, value in raw_data.items():
        # Many2one fields (return [id, name])
        if key in ['parent_id', 'commercial_partner_id', 'state_id', 'country_id', 
                   'user_id', 'activity_user_id', 'activity_type_id', 
                   'create_uid', 'write_uid', 'industry_id']:
            normalized[key] = normalize_many2one(value)
        # Many2many fields (return [id, id, ...] → [{"id": int}])
        elif key in ['category_id', 'child_ids', 'bank_ids', 'channel_ids', 
                     'user_ids', 'activity_ids']:
            normalized[key] = normalize_many2many(value)
        # Boolean flags (NEVER convert to None - use True/False)
        elif key in ['active', 'is_company', 'employee', 'is_public', 
                     'partner_share', 'phone_blacklisted', 'is_blacklisted']:
            normalized[key] = normalize_bool(value)
        # Everything else (data fields - False → None)
        else:
            normalized[key] = normalize_odoo_false(value)
    return normalized


def mask_vat(vat: str) -> str:
    """Mask VAT number for logging compliance"""
    if not vat or len(vat) < 4:
        return "****"
    return vat[:4] + "****"


# ==================== Models ====================

router = APIRouter(tags=["contacts"])



class ContactOut(BaseModel):
    # Core Identity
    id: int
    name: Optional[str] = None
    display_name: Optional[str] = None
    complete_name: Optional[str] = None
    
    # Contact Type & Classification
    is_company: bool = False  # SOURCE OF TRUTH for company/person
    company_type: Optional[str] = None  # Read-only mirror (derived from is_company)
    type: Optional[str] = None  # 'contact' | 'invoice' | 'delivery' | 'other'
    
    # Contact Info
    email: Optional[str] = None
    email_normalized: Optional[str] = None
    phone: Optional[str] = None
    phone_sanitized: Optional[str] = None
    mobile: Optional[str] = None
    website: Optional[str] = None
    
    # Relationships (normalized to {"id": int, "name": str} for Many2one, [{"id": int}] for Many2many)
    parent_id: Optional[dict] = None  # Parent company
    commercial_partner_id: Optional[dict] = None
    child_ids: List[dict] = Field(default_factory=list)  # Child contacts
    
    # Address
    street: Optional[str] = None
    street2: Optional[str] = None
    city: Optional[str] = None
    zip: Optional[str] = None
    state_id: Optional[dict] = None
    country_id: Optional[dict] = None
    country_code: Optional[str] = None
    
    # Business Info
    function: Optional[str] = None  # Job position
    vat: Optional[str] = None  # Tax ID
    company_registry: Optional[str] = None
    category_id: List[dict] = Field(default_factory=list)  # Tags (IDs only for now)
    
    # Business Flags (CRITICAL for ERP)
    customer_rank: int = 0  # Is this a customer?
    supplier_rank: int = 0  # Is this a supplier?
    
    # Company Info
    company_name: Optional[str] = None
    commercial_company_name: Optional[str] = None
    industry_id: Optional[dict] = None
    
    # Images (Strategy: list uses image_128, details lazy-loads image_1920)
    image_128: Optional[str] = None  # Base64 - Use in list views
    image_1920: Optional[str] = None  # Base64 (full size) - Use in detail views only
    
    # Status & Meta (READ-ONLY)
    active: bool = True
    comment: Optional[str] = None
    create_date: Optional[str] = None
    write_date: Optional[str] = None
    create_uid: Optional[dict] = None
    write_uid: Optional[dict] = None
    
    # Communication flags
    is_blacklisted: bool = False
    phone_blacklisted: bool = False
    message_bounce: int = 0

    class Config:
        from_attributes = True



class ContactCreate(BaseModel):
    name: str
    is_company: bool = False  # Allow company creation
    company_type: Optional[str] = None
    
    # Contact info
    email: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    website: Optional[str] = None
    
    # Relationships (send only IDs)
    parent_id: Optional[int] = None
    category_id: Optional[List[int]] = None
    
    # Address
    street: Optional[str] = None
    street2: Optional[str] = None
    city: Optional[str] = None
    zip: Optional[str] = None
    state_id: Optional[int] = None
    country_id: Optional[int] = None
    
    # Business
    function: Optional[str] = None
    vat: Optional[str] = None
    company_registry: Optional[str] = None
    customer_rank: Optional[int] = None
    supplier_rank: Optional[int] = None
    
    comment: Optional[str] = None
    image_1920: Optional[str] = None


class ContactUpdate(BaseModel):
    # All fields optional - same as ContactCreate but nullable
    name: Optional[str] = None
    is_company: Optional[bool] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    website: Optional[str] = None
    parent_id: Optional[int] = None
    category_id: Optional[List[int]] = None
    street: Optional[str] = None
    street2: Optional[str] = None
    city: Optional[str] = None
    zip: Optional[str] = None
    state_id: Optional[int] = None
    country_id: Optional[int] = None
    function: Optional[str] = None
    vat: Optional[str] = None
    company_registry: Optional[str] = None
    customer_rank: Optional[int] = None
    supplier_rank: Optional[int] = None
    comment: Optional[str] = None
    image_1920: Optional[str] = None
    active: Optional[bool] = None
    # NEVER allow editing: create_date, write_date, id, child_ids, create_uid, write_uid



@router.get("/count")
def count_contacts(
    q: Optional[str] = Query(None, description="Search text"),
    type: Optional[str] = Query("both", description="Filter: 'person', 'company', or 'both'"),
    customer_only: bool = Query(False, description="Filter customers only"),
    supplier_only: bool = Query(False, description="Filter suppliers only"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get total count of contacts matching filters.
    Used for pagination UI.
    """
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    # Build domain (same logic as list_contacts)
    domain = []
    
    # Type filter
    if type == "person":
        domain.append(["is_company", "=", False])
    elif type == "company":
        domain.append(["is_company", "=", True])
    # else: both (no filter)
    
    # Business type filters
    if customer_only:
        domain.append(["customer_rank", ">", 0])
    if supplier_only:
        domain.append(["supplier_rank", ">", 0])
    
    # Search filter
    if q:
        search_domain = [
            "|", "|", "|", "|", "|",
            ["name", "ilike", q],
            ["email", "ilike", q],
            ["phone", "ilike", q],
            ["vat", "ilike", q],
            ["company_name", "ilike", q],
        ]
        # Proper AND grouping to prevent precedence issues
        domain = ["&"] + search_domain + domain if domain else search_domain

    try:
        count = odoo_client.execute_kw(
            company,
            "res.partner",
            "search_count",
            [domain],
            {}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    return {"count": count}


@router.get("/", response_model=List[ContactOut])
def list_contacts(
    q: Optional[str] = Query(None, description="Search text (name, email, phone, vat)"),
    type: Optional[str] = Query("both", description="Filter: 'person', 'company', or 'both'"),
    customer_only: bool = Query(False, description="Filter customers only"),
    supplier_only: bool = Query(False, description="Filter suppliers only"),
    limit: int = Query(50, ge=1, le=500, description="Max results"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List contacts from Odoo with filtering and pagination.
    
    Search applies to: name, email, phone, mobile, vat, company_name
    Returns image_128 for list view efficiency (not image_1920).
    """
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    # Build domain
    domain = []
    
    # Type filter
    if type == "person":
        domain.append(["is_company", "=", False])
    elif type == "company":
        domain.append(["is_company", "=", True])
    # else: both (no filter)
    
    # Business type filters
    if customer_only:
        domain.append(["customer_rank", ">", 0])
    if supplier_only:
        domain.append(["supplier_rank", ">", 0])
    
    # Search filter (FIXED: proper AND grouping)
    if q:
        search_domain = [
            "|", "|", "|", "|", "|",
            ["name", "ilike", q],
            ["email", "ilike", q],
            ["phone", "ilike", q],
            ["vat", "ilike", q],
            ["company_name", "ilike", q],
        ]
        # FIXED: Combine search with other filters using AND
        domain = ["&"] + search_domain + domain if domain else search_domain

    # Field list for LIST view (optimized - only standard Odoo fields)
    fields = [
        "id", "name", "display_name",
        "is_company", "type",
        "email", "phone",
        "parent_id", "child_ids",
        "city", "country_id",
        "function", "vat",
        "company_name",
        "image_128",  # Use thumbnail for list
        "active"
    ]

    try:
        contacts = odoo_client.execute_kw(
            company,
            "res.partner",
            "search_read",
            [domain],
            {"fields": fields, "limit": limit, "offset": offset, "order": "name ASC"}
        )
        
        # Normalize all contacts
        normalized_contacts = [normalize_contact(c) for c in contacts]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    return normalized_contacts


@router.get("/{contact_id}", response_model=ContactOut)
def get_contact(contact_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Get a single contact with all fields (including image_1920 for details view)"""
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    # Field list for DETAILS view (standard Odoo fields only)
    fields = [
        "id", "name", "display_name",
        "is_company", "type",
        "email", "phone", "website",
        "parent_id", "child_ids",
        "street", "street2", "city", "zip", "state_id", "country_id",
        "function", "vat", "category_id",
        "company_name",
        "image_128", "image_1920",
        "active", "comment", "create_date", "write_date", "create_uid", "write_uid"
    ]

    try:
        res = odoo_client.execute_kw(
            company,
            "res.partner",
            "read",
            [[contact_id]],
            {"fields": fields}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")

    if not res:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Normalize the contact
    return normalize_contact(res[0])


@router.post("/", response_model=ContactOut)
async def create_contact(
    contact: ContactCreate,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")

    vals = contact.dict(exclude_unset=True)
    # DON'T FORCE is_company = False anymore - allow company creation!
    # Remove mobile if present as it doesn't exist in Odoo
    if "mobile" in vals:
        del vals["mobile"]
    
    # Log company creation

    try:
        new_id = odoo_client.execute_kw(
            company,
            "res.partner",
            "create",
            [vals],
            {}
        )
        
        # Log company creation for audit
        if vals.get("is_company"):
            logger.info(
                f"Company created: {vals.get('name')} (VAT: {mask_vat(vals.get('vat', ''))})",
                extra={
                    "user_id": current_user.id,
                    "company_id": company.id,
                    "action": "company_create",
                    "partner_id": new_id
                }
            )
        
        # Fetch created contact
        fields = [
            "id", "name", "display_name",
            "is_company", "type",
            "email", "phone",
            "parent_id", "child_ids",
            "street", "city", "zip", "country_id",
            "function", "vat",
            "company_name", "image_128", "active"
        ]
        res = odoo_client.execute_kw(
            company,
            "res.partner",
            "read",
            [[new_id]],
            {"fields": fields}
        )
        
        # Normalize before returning
        normalized = normalize_contact(res[0])
        
        from app.api.v1.ws import publish_to_company
        background_tasks.add_task(
            publish_to_company,
            company.id,
            {
                "type": "model_updated",
                "model": "res.partner",
                "action": "create",
                "id": new_id
            }
        )
        
        return normalized
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")


@router.put("/{contact_id}", response_model=ContactOut)
async def update_contact(
    contact_id: int,
    contact: ContactUpdate,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")

    vals = contact.dict(exclude_unset=True)
    # Remove mobile if present as it doesn't exist in Odoo
    if "mobile" in vals:
        del vals["mobile"]
    
    # Log VAT changes for compliance
    if "vat" in vals:
        logger.warning(
            f"VAT updated for contact {contact_id}",
            extra={
                "user_id": current_user.id,
                "company_id": company.id,
                "action": "vat_update",
                "partner_id": contact_id,
                "new_vat_masked": mask_vat(vals["vat"])  # Masked!
            }
        )
    
    try:
        success = odoo_client.execute_kw(
            company,
            "res.partner",
            "write",
            [[contact_id], vals],
            {}
        )
        
        if not success:
             raise HTTPException(status_code=400, detail="Update failed")

        # Fetch updated contact
        fields = [
            "id", "name", "display_name",
            "is_company", "type",
            "email", "phone",
            "parent_id", "child_ids",
            "street", "city", "zip", "country_id",
            "function", "vat",
            "company_name", "image_128", "active"
        ]
        res = odoo_client.execute_kw(
            company,
            "res.partner",
            "read",
            [[contact_id]],
            {"fields": fields}
        )
        
        # Normalize before returning
        normalized = normalize_contact(res[0])
        
        from app.api.v1.ws import publish_to_company
        background_tasks.add_task(
            publish_to_company,
            company.id,
            {
                "type": "model_updated",
                "model": "res.partner",
                "action": "update",
                "id": contact_id
            }
        )
        
        return normalized
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")


@router.delete("/{contact_id}")
async def delete_contact(
    contact_id: int,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    company = db.query(models.Company).filter(
        models.Company.id == current_user.company_id
    ).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    try:
        success = odoo_client.execute_kw(
            company,
            "res.partner",
            "unlink",
            [[contact_id]],
            {},
        )

        if not success:
            raise HTTPException(status_code=400, detail="Delete failed")

        from app.api.v1.ws import publish_to_company
        background_tasks.add_task(
            publish_to_company,
            company.id,
            {
                "type": "model_updated",
                "model": "res.partner",
                "action": "delete",
                "id": contact_id,
            },
        )

        return {"status": "success", "id": contact_id}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Odoo RPC error: {e}")
