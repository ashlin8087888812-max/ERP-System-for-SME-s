from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.api.deps import get_current_user
from app.db.base import get_db
from sqlalchemy.orm import Session
from app.db import models
from app.schemas.discuss import ChannelOut, MessageOut, MessageCreate, SeenUpdate
from app.odoo_client.discuss_service import discuss_service
from app.middleware.rate_limit import RateLimitMiddleware
from app.core.logging import logger

router = APIRouter(tags=["discuss"])

async def get_company(current_user=Depends(get_current_user), db: Session = Depends(get_db)) -> models.Company:
    company = db.query(models.Company).filter(models.Company.id == current_user.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return company

@router.get("/channels", response_model=List[ChannelOut])
async def list_channels(
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """List all channels for current user"""
    # Dynamic resolution by email
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    
    return await discuss_service.get_channels(company, partner_id)

@router.get("/channels/{channel_id}/messages", response_model=List[MessageOut])
async def get_messages(
    channel_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Fetch message history for a channel"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    
    try:
        return await discuss_service.get_messages(company, channel_id, partner_id, limit, offset)
    except PermissionError:
        raise HTTPException(status_code=403, detail="Not a member of this channel")

@router.get("/inbox", response_model=List[MessageOut])
async def get_inbox(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Fetch unread notifications (Inbox)"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    return await discuss_service.get_inbox_messages(company, partner_id, limit, offset)

@router.get("/starred", response_model=List[MessageOut])
async def get_starred(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Fetch starred messages"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    return await discuss_service.get_starred_messages(company, partner_id, limit, offset)

@router.get("/history", response_model=List[MessageOut])
async def get_history(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Fetch history of received messages"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    return await discuss_service.get_history_messages(company, partner_id, limit, offset)

@router.post("/channels/{channel_id}/messages", response_model=MessageOut)
async def post_message(
    channel_id: int,
    msg: MessageCreate,
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Post a new message (Rate limited)"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    
    # Behavior-based flood protection could be injected here via middleware
    # or implemented in the service.
    
    try:
        return await discuss_service.post_message(
            company, channel_id, partner_id, 
            msg.content, msg.parent_id, msg.attachment_ids
        )
    except PermissionError:
        raise HTTPException(status_code=403, detail="Not a member")

@router.post("/channels/{channel_id}/seen")
async def mark_seen(
    channel_id: int,
    data: SeenUpdate,
    company: models.Company = Depends(get_company),
    current_user=Depends(get_current_user)
):
    """Update last seen message ID"""
    partner_id = await discuss_service.get_user_partner_id(company, current_user.id, current_user.email)
    
    await discuss_service.mark_as_read(company, channel_id, partner_id, data.last_message_id)
    return {"status": "success"}
