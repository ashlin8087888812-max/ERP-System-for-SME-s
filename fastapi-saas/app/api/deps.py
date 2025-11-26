from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db import base, crud, models
from app.core import jwt as core_jwt
from app.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

def get_current_user(
    request: Request,
    db: Session = Depends(base.get_db),
    token: str = Depends(oauth2_scheme)
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = core_jwt.decode_token(token)
        if payload is None:
            raise credentials_exception
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(models.User).filter(models.User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    
    # Verify company_id in token matches user's actual company
    token_company_id = payload.get("company_id")
    if token_company_id and int(token_company_id) != user.company_id:
        raise credentials_exception
    
    # Set user in request state for tenant middleware
    request.state.user = user
    return user

def get_current_active_user(current_user: models.User = Depends(get_current_user)) -> models.User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


# RBAC Dependencies

def require_role(required_roles: List[str]):
    """
    Factory function to create role-based access control dependency.
    
    Usage:
        @router.post("/admin-only")
        def admin_endpoint(user = Depends(require_role(["admin"]))):
            ...
    """
    def role_dependency(user: models.User = Depends(get_current_user)):
        # Get user's roles
        user_roles = [role.name for role in user.roles]
        
        # Check if user has any of the required roles
        if not any(role in required_roles for role in user_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required roles: {required_roles}"
            )
        return user
    
    return role_dependency


# Convenience dependencies for common roles
require_admin = require_role(["admin"])
require_supervisor = require_role(["admin", "supervisor"])
require_worker = require_role(["admin", "supervisor", "worker"])


def ensure_branch_access(user: models.User, branch_id: Optional[int]) -> bool:
    """
    Helper to check if user has access to a specific branch.
    
    Rules:
    - Admins have access to all branches
    - Other users only have access to their default branch
    
    Raises HTTPException if access denied.
    """
    # Get user's roles
    user_roles = [role.name for role in user.roles]
    
    # Admins have access to all branches
    if "admin" in user_roles:
        return True
    
    # Check branch access for non-admins
    if branch_id and branch_id != user.default_branch_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No access to this branch"
        )
    
    return True
