"""
SIEM (Security Information and Event Management) integration.

Features:
- CEF (Common Event Format) manual formatting
- Webhook delivery for cloud SIEM (Splunk, Datadog, etc.)
- Async fire-and-forget (never blocks requests)
- Security event categorization
- Timeout protection and circuit breaker
"""
import logging
import json
import time
import asyncio
from typing import Optional, Dict, Any
from datetime import datetime
from collections import defaultdict
from threading import Lock

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


# Security event severity mapping
SECURITY_EVENTS = {
    "AUTH_LOGIN_FAILURE": {"severity": 5, "category": "authentication"},
    "AUTHZ_DENIED": {"severity": 5, "category": "authorization"},
    "RATE_LIMIT_EXCEEDED": {"severity": 3, "category": "abuse"},
    "SECURITY_VIOLATION": {"severity": 8, "category": "threat"},
    "DATA_BREACH_ATTEMPT": {"severity": 10, "category": "data_loss"},
    "SUSPICIOUS_ACTIVITY": {"severity": 7, "category": "threat"},
}


class SIEMIntegration:
    """SIEM integration with async webhook delivery and circuit breaker."""
    
    def __init__(self):
        self.client: Optional[httpx.AsyncClient] = None
        self.circuit_breaker_failures = 0
        self.circuit_breaker_threshold = 5
        self.circuit_breaker_reset_time = 300  # 5 minutes
        self.last_failure_time = 0
        self.lock = Lock()
    
    async def initialize(self):
        """Initialize async HTTP client."""
        if not settings.SIEM_ENABLED:
            return
        
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(settings.LOKI_TIMEOUT_SECONDS),
            limits=httpx.Limits(max_keepalive_connections=5, max_connections=10)
        )
        logger.info(f"SIEM integration initialized ({settings.SIEM_TYPE})")
    
    async def close(self):
        """Close HTTP client."""
        if self.client:
            await self.client.aclose()
    
    def _is_circuit_open(self) -> bool:
        """Check if circuit breaker is open."""
        with self.lock:
            if self.circuit_breaker_failures >= self.circuit_breaker_threshold:
                # Check if enough time has passed to reset
                if time.time() - self.last_failure_time > self.circuit_breaker_reset_time:
                    self.circuit_breaker_failures = 0
                    logger.info("SIEM circuit breaker reset")
                    return False
                return True
            return False
    
    def _record_failure(self):
        """Record a failure for circuit breaker."""
        with self.lock:
            self.circuit_breaker_failures += 1
            self.last_failure_time = time.time()
            if self.circuit_breaker_failures >= self.circuit_breaker_threshold:
                logger.warning("SIEM circuit breaker opened due to repeated failures")
    
    def _record_success(self):
        """Record a success to potentially reset circuit breaker."""
        with self.lock:
            if self.circuit_breaker_failures > 0:
                self.circuit_breaker_failures = max(0, self.circuit_breaker_failures - 1)
    
    def format_cef(
        self,
        event_type: str,
        severity: int,
        message: str,
        source_ip: Optional[str] = None,
        user_id: Optional[str] = None,
        custom_fields: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Format event as CEF (Common Event Format).
        
        CEF Format: CEF:Version|Device Vendor|Device Product|Device Version|Signature ID|Name|Severity|Extension
        """
        # CEF header
        version = 0
        device_vendor = "Syncerity"
        device_product = settings.PROJECT_NAME
        device_version = "1.0"
        signature_id = event_type
        name = message
        
        # Build CEF string
        cef_header = f"CEF:{version}|{device_vendor}|{device_product}|{device_version}|{signature_id}|{name}|{severity}"
        
        # Extensions
        extensions = []
        if source_ip:
            extensions.append(f"src={source_ip}")
        if user_id:
            extensions.append(f"suser={user_id}")
        
        # Add custom fields
        if custom_fields:
            for key, value in custom_fields.items():
                # CEF field naming convention
                extensions.append(f"{key}={value}")
        
        cef_message = cef_header
        if extensions:
            cef_message += "|" + " ".join(extensions)
        
        return cef_message
    
    async def send_event(
        self,
        event_type: str,
        message: str,
        severity: Optional[int] = None,
        source_ip: Optional[str] = None,
        user_id: Optional[str] = None,
        custom_fields: Optional[Dict[str, Any]] = None
    ):
        """
        Send security event to SIEM (async, fire-and-forget).
        
        Args:
            event_type: Type of security event
            message: Event message
            severity: Severity level (1-10)
            source_ip: Source IP address
            user_id: User ID
            custom_fields: Additional fields
        """
        if not settings.SIEM_ENABLED or not self.client:
            return
        
        # Circuit breaker check
        if self._is_circuit_open():
            logger.debug("SIEM circuit breaker open, skipping event")
            return
        
        # Get event metadata
        event_meta = SECURITY_EVENTS.get(event_type, {"severity": 5, "category": "other"})
        if severity is None:
            severity = event_meta["severity"]
        
        try:
            # Format based on SIEM type
            if settings.SIEM_TYPE == "webhook":
                payload = {
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "event_type": event_type,
                    "message": message,
                    "severity": severity,
                    "category": event_meta["category"],
                    "source_ip": source_ip,
                    "user_id": user_id,
                    "service": settings.PROJECT_NAME,
                    "environment": settings.ENVIRONMENT,
                    **(custom_fields or {})
                }
                
                headers = {"Content-Type": "application/json"}
                if settings.SIEM_API_KEY:
                    headers["Authorization"] = f"Bearer {settings.SIEM_API_KEY}"
                
                # Async send (fire-and-forget)
                response = await self.client.post(
                    settings.SIEM_ENDPOINT,
                    json=payload,
                    headers=headers
                )
                response.raise_for_status()
                self._record_success()
                
            elif settings.SIEM_TYPE == "cef":
                # CEF format for syslog or other consumers
                cef_message = self.format_cef(
                    event_type=event_type,
                    severity=severity,
                    message=message,
                    source_ip=source_ip,
                    user_id=user_id,
                    custom_fields=custom_fields
                )
                
                # Send CEF to webhook endpoint
                response = await self.client.post(
                    settings.SIEM_ENDPOINT,
                    content=cef_message,
                    headers={"Content-Type": "text/plain"}
                )
                response.raise_for_status()
                self._record_success()
            
            logger.debug(f"SIEM event sent: {event_type}")
            
        except Exception as e:
            # Never fail the request due to SIEM
            self._record_failure()
            logger.warning(f"Failed to send SIEM event (non-blocking): {e}")
    
    def send_event_sync(self, *args, **kwargs):
        """Synchronous wrapper for send_event (creates async task)."""
        if not settings.SIEM_ASYNC_ONLY:
            # Block and wait (not recommended)
            asyncio.run(self.send_event(*args, **kwargs))
        else:
            # Fire and forget (recommended)
            try:
                loop = asyncio.get_event_loop()
                loop.create_task(self.send_event(*args, **kwargs))
            except RuntimeError:
                # No event loop, skip
                logger.debug("No event loop available for SIEM event")


# Global SIEM integration instance
siem = SIEMIntegration()


# Convenience functions
async def log_security_event(
    event_type: str,
    message: str,
    source_ip: Optional[str] = None,
    user_id: Optional[str] = None,
    **custom_fields
):
    """Log security event to SIEM."""
    await siem.send_event(
        event_type=event_type,
        message=message,
        source_ip=source_ip,
        user_id=user_id,
        custom_fields=custom_fields
    )


def log_security_event_sync(
    event_type: str,
    message: str,
    source_ip: Optional[str] = None,
    user_id: Optional[str] = None,
    **custom_fields
):
    """Log security event to SIEM (sync wrapper)."""
    siem.send_event_sync(
        event_type=event_type,
        message=message,
        source_ip=source_ip,
        user_id=user_id,
        custom_fields=custom_fields
    )
