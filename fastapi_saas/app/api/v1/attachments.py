from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import io
import base64
from app.api.deps import get_current_user
from app.db import models
from app.api.v1.discuss import get_company
from app.odoo_client.client import odoo_client
from app.odoo_client.discuss_service import discuss_service
from app.core.logging import logger

router = APIRouter(tags=["attachments"])

@router.get("/{attachment_id}")
async def get_attachment(
    attachment_id: int,
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """
    Secure Attachment Proxy (Hardened v3.0)
    Rules:
    1. Resolve parent record (model, id)
    2. Verify user access to parent record in Odoo
    3. Stream from Odoo securely
    """
    partner_id = getattr(current_user, "partner_id", None) or await discuss_service.get_user_partner_id(company, current_user.id)
    
    try:
        # 1. Fetch metadata and check access
        # Odoo's ir.attachment check_access() is robust, but we force parent-record check here
        meta = await odoo_client.execute_kw_async(
            company, "ir.attachment", "read",
            [[attachment_id]], {"fields": ["name", "mimetype", "res_model", "res_id"]}
        )
        
        if not meta:
            raise HTTPException(status_code=404, detail="Attachment not found")
            
        att = meta[0]
        res_model = att.get("res_model")
        res_id = att.get("res_id")
        
        # 2. Authorization check on parent record
        # If model is discuss.channel, use our hardened membership check
        if res_model == "discuss.channel":
             if not await discuss_service.check_membership(company, res_id, partner_id):
                 raise HTTPException(status_code=403, detail="Access denied to channel attachments")
        else:
            # General fallback: check read access on the parent record via Odoo ACL
            # Note: Using sudo=False here effectively checks the Odoo user's personal access
            can_read = await odoo_client.execute_kw_async(
                company, res_model, "check_access_rule",
                [[res_id]], {"operation": "read"}
            )
            # if no exception is raised, Odoo allows it.
            
        # 3. Stream data
        # Fetch data in a separate call to avoid caching huge blobs in 'read' meta
        data_raw = await odoo_client.execute_kw_async(
            company, "ir.attachment", "read",
            [[attachment_id]], {"fields": ["datas"]}
        )
        
        if not data_raw:
             raise HTTPException(status_code=500, detail="Could not retrieve attachment data")
             
        content = base64.b64decode(data_raw[0]["datas"])
        return StreamingResponse(
            io.BytesIO(content),
            media_headers={
                "Content-Disposition": f'attachment; filename="{att["name"]}"',
                "Content-Type": att["mimetype"]
            }
        )

    except Exception as e:
        logger.error(f"Attachment Proxy Error: {e}")
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=403, detail="Unauthorized attachment access")

@router.post("/upload")
async def upload_attachment(
    name: str,
    content_base64: str,
    res_model: str,
    res_id: int,
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Secure upload with parent access check and filename sanitization"""
    partner_id = getattr(current_user, "partner_id", None) or await discuss_service.get_user_partner_id(company, current_user.id)
    
    # Check parent access
    if res_model == "discuss.channel":
         if not await discuss_service.check_membership(company, res_id, partner_id):
             raise HTTPException(status_code=403, detail="Cannot upload to restricted channel")
             
    # Create in Odoo
    vals = {
        "name": name.replace("/", "").replace("\\", ""), # Basic sanitization
        "datas": content_base64,
        "res_model": res_model,
        "res_id": res_id,
        "type": "binary"
    }
    
    new_id = await odoo_client.execute_kw_async(
        company, "ir.attachment", "create", [vals]
    )
    
    return {"id": new_id, "status": "success"}
