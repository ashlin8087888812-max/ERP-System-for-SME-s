from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timedelta
from app.db import crud, models
from app.db.base import get_db
from app.core import security, jwt
from app.config import settings
from app.db import crud_refresh_token
from app.core.logging import logger

router = APIRouter()

# === Request/Response Models ===

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    company_name: str
    company_db_name: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds until access token expires

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class LogoutResponse(BaseModel):
    message: str = "Successfully logged out"

class LogoutAllResponse(BaseModel):
    message: str
    revoked_count: int

# === Helper Functions ===

def create_tokens_for_user(
    user: models.User,
    company: models.Company,
    db: Session,
    request: Optional[Request] = None
) -> TokenResponse:
    """
    Create both access and refresh tokens for a user.
    
    Implements Option B: Embeds refresh token ID (rtid) in JWT.
    
    Args:
        user: User object
        company: Company object
        db: Database session
        request: Optional request object for IP/user-agent tracking
        
    Returns:
        TokenResponse with both tokens
    """
    # Generate refresh token
    refresh_token = security.generate_refresh_token()
    refresh_expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXP_DAYS)
    
    # Extract metadata from request if available
    ip_address = None
    user_agent = None
    if request:
        ip_address = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent")
    
    # Store hashed refresh token in DB
    db_refresh_token = crud_refresh_token.create_refresh_token(
        db=db,
        user_id=user.id,
        token=refresh_token,
        expires_at=refresh_expires_at,
        ip_address=ip_address,
        user_agent=user_agent
    )
    
    # Create access token JWT with rtid (Option B)
    access_token_expires = timedelta(minutes=settings.JWT_EXP_MINUTES)
    access_token = jwt.create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "company_id": company.id,
            "db_name": company.db_name,
            "role": "admin",  # TODO: Fetch actual role
            "rtid": db_refresh_token.id  # CRITICAL: Embed refresh token ID for logout
        },
        expires_delta=access_token_expires,
    )
    
    # SECURITY: Never log the raw refresh token
    logger.info(
        "Tokens created",
        extra={
            "user_id": user.id,
            "refresh_token_id": db_refresh_token.id,
            "ip_address": ip_address
        }
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,  # Send raw token to client (only time it's exposed)
        token_type="bearer",
        expires_in=settings.JWT_EXP_MINUTES * 60
    )

# === Auth Endpoints ===

@router.post("/signup", response_model=TokenResponse)
def signup(user_in: UserCreate, request: Request, db: Session = Depends(get_db)):
    """
    Register a new user and company.
    Returns both access and refresh tokens.
    """
    user = crud.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    
    company = crud.get_company_by_name(db, name=user_in.company_name)
    if company:
        raise HTTPException(
            status_code=400,
            detail="The company with this name already exists.",
        )
        
    # Create Company (odoo_host defaults to settings.ODOO_HOST)
    company = crud.create_company(
        db=db,
        name=user_in.company_name,
        db_name=user_in.company_db_name,
    )
    
    # Create User
    user = crud.create_user(
        db=db,
        email=user_in.email,
        full_name=user_in.full_name,
        company_id=company.id,
        password_hash=security.get_password_hash(user_in.password)
    )
    
    # Generate tokens (includes refresh token)
    return create_tokens_for_user(user, company, db, request)

@router.post("/login", response_model=TokenResponse)
def login(login_data: LoginRequest, request: Request, db: Session = Depends(get_db)):
    """
    Authenticate user and return both access and refresh tokens.
    """
    user = crud.get_user_by_email(db, email=login_data.email)
    if not user or not security.verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    company = user.company
    
    # Generate tokens (includes refresh token)
    return create_tokens_for_user(user, company, db, request)

@router.post("/refresh", response_model=TokenResponse)
def refresh_token(
    refresh_data: RefreshRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Refresh access token using a valid refresh token.
    
    Implements STRICT TOKEN ROTATION:
    1. Validate existing refresh token
    2. Generate new refresh token
    3. Revoke old refresh token IMMEDIATELY
    4. Return new access token (with new rtid) + new refresh token
    5. Old token cannot be reused (revoked)
    """
    # Validate refresh token
    db_token = crud_refresh_token.validate_refresh_token(db, refresh_data.refresh_token)
    
    if not db_token:
        # Token is invalid: either doesn't exist, revoked, or expired
        logger.warning(
            "Invalid refresh token attempt",
            extra={
                "token_prefix": refresh_data.refresh_token[:10]  # Only log prefix
            }
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get user and company
    user = db_token.user
    company = user.company
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive",
        )
    
    # STRICT ROTATION: Generate new refresh token
    new_refresh_token = security.generate_refresh_token()
    new_refresh_expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXP_DAYS)
    
    # Extract metadata
    ip_address = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    
    # Store new refresh token
    new_db_token = crud_refresh_token.create_refresh_token(
        db=db,
        user_id=user.id,
        token=new_refresh_token,
        expires_at=new_refresh_expires_at,
        ip_address=ip_address,
        user_agent=user_agent
    )
    
    # IMMEDIATELY revoke old refresh token (STRICT ROTATION)
    crud_refresh_token.revoke_refresh_token(db, db_token.id)
    
    # Create new access token with NEW rtid
    access_token_expires = timedelta(minutes=settings.JWT_EXP_MINUTES)
    access_token = jwt.create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "company_id": company.id,
            "db_name": company.db_name,
            "role": "admin",  # TODO: Fetch actual role
            "rtid": new_db_token.id  # NEW rtid for new token
        },
        expires_delta=access_token_expires,
    )
    
    logger.info(
        "Token rotated",
        extra={
            "user_id": user.id,
            "old_token_id": db_token.id,
            "new_token_id": new_db_token.id
        }
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,  # Return NEW refresh token
        token_type="bearer",
        expires_in=settings.JWT_EXP_MINUTES * 60
    )

@router.post("/logout", response_model=LogoutResponse)
def logout(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Logout user by revoking their refresh token.
    
    Implements Option B: Extracts rtid from JWT and revokes that specific token.
    No need for client to send refresh token.
    """
    # Extract access token from Authorization header
    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = auth_header.split(" ")[1]
    
    # Decode JWT to get rtid
    payload = jwt.decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Extract rtid (refresh token ID) from JWT
    rtid = payload.get("rtid")
    if not rtid:
        # Old token without rtid (backward compatibility)
        logger.warning(
            "Logout attempt with token without rtid",
            extra={"user_id": payload.get("sub")}
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token does not contain refresh token ID",
        )
    
    # Revoke the specific refresh token
    revoked = crud_refresh_token.revoke_refresh_token(db, rtid)
    
    if not revoked:
        # Token might already be revoked or doesn't exist
        logger.info(
            "Logout attempted but token not found",
            extra={"rtid": rtid}
        )
    else:
        logger.info(
            "User logged out",
            extra={
                "user_id": payload.get("sub"),
                "rtid": rtid
            }
        )
    
    return LogoutResponse(message="Successfully logged out")

@router.post("/logout-all", response_model=LogoutAllResponse)
def logout_all(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Logout user from all devices by revoking all their refresh tokens.
    """
    # Extract access token from Authorization header
    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = auth_header.split(" ")[1]
    
    # Decode JWT to get user ID
    payload = jwt.decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = int(payload.get("sub"))
    
    # Revoke all refresh tokens for this user
    revoked_count = crud_refresh_token.revoke_all_user_tokens(db, user_id)
    
    logger.info(
        "User logged out from all devices",
        extra={
            "user_id": user_id,
            "revoked_count": revoked_count
        }
    )
    
    return LogoutAllResponse(
        message=f"Successfully logged out from all devices",
        revoked_count=revoked_count
    )
