"""
Enterprise audit logging with WORM storage and GDPR compliance.

Features:
- Immutable audit event logging
- Cryptographic event signing for tamper detection
- GDPR-compliant pseudonymization
- Multiple storage backends (file, S3, database)
- Automatic retention policy enforcement
"""
import logging
import json
import hashlib
import hmac
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Any
from uuid import UUID, uuid4
from enum import Enum

from pydantic import BaseModel
from app.config import settings

logger = logging.getLogger(__name__)


# === AUDIT EVENT TYPES ===

class AuditEventType(str, Enum):
    """Audit event types for security and compliance."""
    # Authentication
    AUTH_LOGIN_SUCCESS = "AUTH_LOGIN_SUCCESS"
    AUTH_LOGIN_FAILURE = "AUTH_LOGIN_FAILURE"
    AUTH_LOGOUT = "AUTH_LOGOUT"
    AUTH_TOKEN_REFRESH = "AUTH_TOKEN_REFRESH"
    AUTH_TOKEN_REVOKE = "AUTH_TOKEN_REVOKE"
    
    # Authorization
    AUTHZ_DENIED = "AUTHZ_DENIED"
    
    # Data Access
    DATA_READ = "DATA_READ"
    DATA_CREATE = "DATA_CREATE"
    DATA_UPDATE = "DATA_UPDATE"
    DATA_DELETE = "DATA_DELETE"
    DATA_EXPORT = "EXPORT_DATA"
    
    # Security
    SECURITY_VIOLATION = "SECURITY_VIOLATION"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    
    # Administrative
    ADMIN_ACTION = "ADMIN_ACTION"
    CONFIG_CHANGE = "CONFIG_CHANGE"


class AuditOutcome(str, Enum):
    """Audit event outcomes."""
    SUCCESS = "SUCCESS"
    FAILURE = "FAILURE"


# === AUDIT EVENT MODEL ===

class AuditEvent(BaseModel):
    """
    Immutable audit event (Schema v1.0).
    
    GDPR Compliance: Uses pseudonymized IDs, not direct PII.
    """
    schema_version: str = "1.0"
    event_id: UUID
    timestamp: datetime
    event_type: AuditEventType
    actor_pseudonym_id: str  # Pseudonymous ID, not real user_id
    tenant_id: str
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None  # Pseudonymized if PII
    action: str  # CREATE, READ, UPDATE, DELETE
    outcome: AuditOutcome
    ip_address: Optional[str] = None  # Hashed or pseudonymized
    user_agent: Optional[str] = None
    metadata: Dict[str, Any] = {}  # No direct PII
    signature: Optional[str] = None  # HMAC for tamper detection
    
    class Config:
        use_enum_values = True


# === PSEUDONYM MAPPING (for GDPR compliance) ===

# In-memory cache for pseudonyms (in production, use Redis or database)
_pseudonym_cache: Dict[str, str] = {}


def get_or_create_pseudonym(user_id: str) -> str:
    """
    Get or create pseudonymous ID for user.
    
    In production, this should query/store in database table that can be deleted
    for GDPR "right to be forgotten" compliance.
    
    Args:
        user_id: Real user ID
        
    Returns:
        Pseudonymous ID to use in logs
    """
    if not settings.USE_PSEUDONYMOUS_IDS:
        return user_id
    
    if user_id in _pseudonym_cache:
        return _pseudonym_cache[user_id]
    
    # Create deterministic pseudonym (for consistency across logs)
    pseudonym = f"pseudo_{hashlib.sha256(user_id.encode()).hexdigest()[:16]}"
    _pseudonym_cache[user_id] = pseudonym
    
    # TODO: Store mapping in database:
    # INSERT INTO user_pseudonyms (user_id, pseudonym_id, created_at)
    # VALUES (user_id, pseudonym, datetime.utcnow())
    # ON CONFLICT (user_id) DO NOTHING
    
    return pseudonym


def hash_ip_address(ip: str) -> str:
    """Hash IP address for GDPR compliance (one-way hash)."""
    if not settings.USE_PSEUDONYMOUS_IDS:
        return ip
    return hashlib.sha256(ip.encode()).hexdigest()[:32]


# === AUDIT LOGGER ===

class AuditLogger:
    """Enterprise audit logger with WORM storage."""
    
    def __init__(self):
        self.signing_key = settings.SECRET_KEY.encode()
        
        # Ensure audit log directory exists
        if settings.AUDIT_LOG_STORAGE == "file":
            Path(settings.AUDIT_LOG_PATH).mkdir(parents=True, exist_ok=True)
    
    def log_event(
        self,
        event_type: AuditEventType,
        actor_id: str,  # Real user ID
        tenant_id: str,
        action: str,
        outcome: AuditOutcome,
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ):
        """
        Log an audit event with automatic pseudonymization.
        
        Args:
            event_type: Type of audit event
            actor_id: Real user ID (will be pseudonymized)
            tenant_id: Tenant ID
            action: Action performed
            outcome: Event outcome
            resource_type: Type of resource accessed
            resource_id: ID of resource (will be pseudonymized if PII)
            ip_address: Client IP (will be hashed)
            user_agent: User agent string
            metadata: Additional event metadata (no PII allowed)
        """
        if not settings.AUDIT_LOG_ENABLED:
            return
        
        try:
            # Create pseudonymized event
            event = AuditEvent(
                event_id=uuid4(),
                timestamp=datetime.utcnow(),
                event_type=event_type,
                actor_pseudonym_id=get_or_create_pseudonym(actor_id),
                tenant_id=tenant_id,
                resource_type=resource_type,
                resource_id=resource_id,  # Assume non-PII or already pseudonymized
                action=action,
                outcome=outcome,
                ip_address=hash_ip_address(ip_address) if ip_address else None,
                user_agent=user_agent,
                metadata=metadata or {},
            )
            
            # Sign event for tamper detection
            event.signature = self._sign_event(event)
            
            # Store event (WORM)
            self._store_event(event)
            
            # Also log to application logs for searchability
            logger.info(
                f"AUDIT: {event_type.value}",
                extra={
                    "event_id": str(event.event_id),
                    "actor_pseudonym": event.actor_pseudonym_id,
                    "tenant_id": tenant_id,
                    "outcome": outcome.value,
                }
            )
            
        except Exception as e:
            # Never fail the request due to audit logging
            logger.error(f"Failed to log audit event: {e}")
    
    def _sign_event(self, event: AuditEvent) -> str:
        """Create HMAC signature for event tamper detection."""
        # Create canonical representation
        canonical = json.dumps({
            "event_id": str(event.event_id),
            "timestamp": event.timestamp.isoformat(),
            "event_type": event.event_type,
            "actor": event.actor_pseudonym_id,
            "tenant_id": event.tenant_id,
            "action": event.action,
            "outcome": event.outcome,
        }, sort_keys=True)
        
        # Create HMAC signature
        signature = hmac.new(
            self.signing_key,
            canonical.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return signature
    
    def verify_event_signature(self, event: AuditEvent) -> bool:
        """Verify event signature to detect tampering."""
        stored_signature = event.signature
        event.signature = None
        calculated_signature = self._sign_event(event)
        event.signature = stored_signature
        return calculated_signature == stored_signature
    
    def _store_event(self, event: AuditEvent):
        """Store event in WORM-compliant storage."""
        if settings.AUDIT_LOG_STORAGE == "file":
            self._store_to_file(event)
        elif settings.AUDIT_LOG_STORAGE == "s3":
            self._store_to_s3(event)
        elif settings.AUDIT_LOG_STORAGE == "database":
            self._store_to_database(event)
    
    def _store_to_file(self, event: AuditEvent):
        """Store event to append-only file."""
        # Use date-based partitioning for manageability
        date_str = event.timestamp.strftime("%Y-%m-%d")
        log_file = Path(settings.AUDIT_LOG_PATH) / f"audit_{date_str}.jsonl"
        
        # Append to file (JSONL format)
        with open(log_file, 'a') as f:
            f.write(event.model_dump_json() + '\n')
        
        # Set file permissions to append-only if WORM enabled
        if settings.AUDIT_LOG_WORM_ENABLED:
            try:
                import stat
                log_file.chmod(stat.S_IRUSR | stat.S_IRGRP | stat.S_IROTH)  # Read-only
            except Exception as e:
                logger.warning(f"Could not set WORM permissions: {e}")
    
    def _store_to_s3(self, event: AuditEvent):
        """Store event to S3 with object lock (WORM)."""
        if not settings.AUDIT_LOG_S3_BUCKET:
            logger.error("S3 bucket not configured for audit logging")
            return
        
        try:
            import boto3
            from botocore.exceptions import ClientError
            
            s3 = boto3.client('s3')
            
            # Use date-based partitioning
            date_str = event.timestamp.strftime("%Y/%m/%d")
            key = f"audit/{date_str}/{event.event_id}.json"
            
            # Upload with object lock if WORM enabled
            put_args = {
                'Bucket': settings.AUDIT_LOG_S3_BUCKET,
                'Key': key,
                'Body': event.model_dump_json(),
                'ContentType': 'application/json',
            }
            
            if settings.AUDIT_LOG_WORM_ENABLED:
                # Set retention until retention date
                retention_date = datetime.utcnow() + timedelta(days=settings.AUDIT_LOG_RETENTION_DAYS)
                put_args['ObjectLockMode'] = 'COMPLIANCE'
                put_args['ObjectLockRetainUntilDate'] = retention_date
            
            s3.put_object(**put_args)
            
        except Exception as e:
            logger.error(f"Failed to store audit event to S3: {e}")
    
    def _store_to_database(self, event: AuditEvent):
        """Store event to database with RLS policies."""
        # TODO: Implement database storage with:
        # - Row-level security (RLS) for multi-tenancy
        # - Indexes on timestamp, event_type, actor, tenant_id
        # - Partition by date for performance
        # - Audit triggers to prevent UPDATE/DELETE
        pass


# Global audit logger instance
audit_logger = AuditLogger()


# === CONVENIENCE FUNCTIONS ===

def log_auth_success(user_id: str, tenant_id: str, ip_address: str, user_agent: str):
    """Log successful authentication."""
    audit_logger.log_event(
        event_type=AuditEventType.AUTH_LOGIN_SUCCESS,
        actor_id=user_id,
        tenant_id=tenant_id,
        action="LOGIN",
        outcome=AuditOutcome.SUCCESS,
        ip_address=ip_address,
        user_agent=user_agent,
    )


def log_auth_failure(email: str, tenant_id: str, ip_address: str, user_agent: str, reason: str):
    """Log failed authentication attempt."""
    audit_logger.log_event(
        event_type=AuditEventType.AUTH_LOGIN_FAILURE,
        actor_id=email,  # Use email as identifier for failed attempts
        tenant_id=tenant_id or "unknown",
        action="LOGIN",
        outcome=AuditOutcome.FAILURE,
        ip_address=ip_address,
        user_agent=user_agent,
        metadata={"reason": reason},
    )


def log_authz_denied(user_id: str, tenant_id: str, resource: str, action: str):
    """Log authorization denial."""
    audit_logger.log_event(
        event_type=AuditEventType.AUTHZ_DENIED,
        actor_id=user_id,
        tenant_id=tenant_id,
        action=action,
        outcome=AuditOutcome.FAILURE,
        resource_type=resource,
    )


def log_data_access(
    user_id: str,
    tenant_id: str,
    resource_type: str,
    resource_id: str,
    action: str,
    outcome: AuditOutcome = AuditOutcome.SUCCESS,
    metadata: Optional[Dict] = None
):
    """Log data access (CREATE, READ, UPDATE, DELETE)."""
    event_type_map = {
        "CREATE": AuditEventType.DATA_CREATE,
        "READ": AuditEventType.DATA_READ,
        "UPDATE": AuditEventType.DATA_UPDATE,
        "DELETE": AuditEventType.DATA_DELETE,
    }
    
    audit_logger.log_event(
        event_type=event_type_map.get(action.upper(), AuditEventType.DATA_READ),
        actor_id=user_id,
        tenant_id=tenant_id,
        resource_type=resource_type,
        resource_id=resource_id,
        action=action,
        outcome=outcome,
        metadata=metadata,
    )
