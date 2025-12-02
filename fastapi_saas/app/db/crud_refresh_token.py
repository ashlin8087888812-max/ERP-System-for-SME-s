"""
CRUD operations for refresh tokens.

Handles creation, retrieval, revocation, and cleanup of stateful refresh tokens.
All operations follow enterprise-grade security practices.
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timedelta
from typing import Optional
from app.db.models import RefreshToken
from app.core.security import hash_token
from app.config import settings


def create_refresh_token(
    db: Session,
    user_id: int,
    token: str,
    expires_at: datetime,
    device_fingerprint: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
) -> RefreshToken:
    """
    Create a new refresh token in the database.
    
    IMPORTANT: Always pass the RAW token to this function.
    It will be hashed automatically before storage.
    
    Args:
        db: Database session
        user_id: User ID this token belongs to
        token: RAW refresh token (will be hashed)
        expires_at: Expiration datetime
        device_fingerprint: Optional device identifier
        ip_address: Optional IP address
        user_agent: Optional user agent string
        
    Returns:
        RefreshToken: Created token object (with id for embedding in JWT)
    """
    token_hash_value = hash_token(token)
    
    db_token = RefreshToken(
        user_id=user_id,
        token_hash=token_hash_value,
        expires_at=expires_at,
        device_fingerprint=device_fingerprint,
        ip_address=ip_address,
        user_agent=user_agent
    )
    
    db.add(db_token)
    db.commit()
    db.refresh(db_token)
    
    return db_token


def get_refresh_token_by_hash(
    db: Session,
    token_hash: str
) -> Optional[RefreshToken]:
    """
    Retrieve refresh token by its hash.
    
    Args:
        db: Database session
        token_hash: SHA-256 hash of the token
        
    Returns:
        Optional[RefreshToken]: Token if found, None otherwise
    """
    return db.query(RefreshToken).filter(
        RefreshToken.token_hash == token_hash
    ).first()


def get_refresh_token_by_id(
    db: Session,
    token_id: int
) -> Optional[RefreshToken]:
    """
    Retrieve refresh token by its ID.
    Used for logout (when rtid is extracted from JWT).
    
    Args:
        db: Database session
        token_id: Token ID
        
    Returns:
        Optional[RefreshToken]: Token if found, None otherwise
    """
    return db.query(RefreshToken).filter(
        RefreshToken.id == token_id
    ).first()


def validate_refresh_token(
    db: Session,
    token: str
) -> Optional[RefreshToken]:
    """
    Validate a refresh token and return it if valid.
    
    Checks:
    - Token exists in database
    - Not revoked
    - Not expired
    
    Args:
        db: Database session
        token: RAW refresh token
        
    Returns:
        Optional[RefreshToken]: Token if valid, None otherwise
    """
    token_hash_value = hash_token(token)
    
    db_token = db.query(RefreshToken).filter(
        and_(
            RefreshToken.token_hash == token_hash_value,
            RefreshToken.revoked == False,
            RefreshToken.expires_at > datetime.utcnow()
        )
    ).first()
    
    return db_token


def revoke_refresh_token(
    db: Session,
    token_id: int
) -> bool:
    """
    Revoke a refresh token by ID.
    
    Args:
        db: Database session
        token_id: Token ID to revoke
        
    Returns:
        bool: True if revoked, False if not found
    """
    db_token = db.query(RefreshToken).filter(
        RefreshToken.id == token_id
    ).first()
    
    if not db_token:
        return False
    
    db_token.revoked = True
    db_token.revoked_at = datetime.utcnow()
    db.commit()
    
    return True


def revoke_all_user_tokens(
    db: Session,
    user_id: int
) -> int:
    """
    Revoke all refresh tokens for a user.
    Used for "logout from all devices".
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        int: Number of tokens revoked
    """
    result = db.query(RefreshToken).filter(
        and_(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked == False
        )
    ).update(
        {
            'revoked': True,
            'revoked_at': datetime.utcnow()
        },
        synchronize_session=False
    )
    
    db.commit()
    return result


def update_token_last_used(
    db: Session,
    token_id: int
) -> None:
    """
    Update the last_used_at timestamp for a token.
    Called when token is successfully used for refresh.
    
    Args:
        db: Database session
        token_id: Token ID
    """
    db.query(RefreshToken).filter(
        RefreshToken.id == token_id
    ).update(
        {'last_used_at': datetime.utcnow()},
        synchronize_session=False
    )
    
    db.commit()


def delete_expired_tokens(
    db: Session
) -> int:
    """
    Delete all expired refresh tokens from the database.
    Called by Celery periodic task for cleanup.
    
    Args:
        db: Database session
        
    Returns:
        int: Number of tokens deleted
    """
    result = db.query(RefreshToken).filter(
        RefreshToken.expires_at < datetime.utcnow()
    ).delete(synchronize_session=False)
    
    db.commit()
    return result


def get_user_active_tokens_count(
    db: Session,
    user_id: int
) -> int:
    """
    Get count of active (non-revoked, non-expired) tokens for a user.
    Useful for session limits or security monitoring.
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        int: Count of active tokens
    """
    return db.query(RefreshToken).filter(
        and_(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked == False,
            RefreshToken.expires_at > datetime.utcnow()
        )
    ).count()
