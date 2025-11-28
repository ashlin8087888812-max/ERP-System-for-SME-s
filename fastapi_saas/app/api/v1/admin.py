from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import models
from app.api import deps
from app.db.base import get_db

router = APIRouter()

@router.get("/users", response_model=List[dict])
async def read_users_admin(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(deps.require_admin),
) -> Any:
    """
    Retrieve all users (Admin only).
    """
    # Admin can see all users in their company
    users = db.query(models.User).filter(
        models.User.company_id == current_user.company_id
    ).offset(skip).limit(limit).all()
    
    return [{"id": u.id, "email": u.email, "full_name": u.full_name, "is_active": u.is_active} for u in users]
