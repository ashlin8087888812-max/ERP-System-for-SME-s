"""
Enhanced Sentry integration with correlation and trace context.

Features:
- Auto-inject correlation_id and trace_id
- Return sentry_event_id for log correlation
- Tag events with tenant_id and user_id
- Custom breadcrumbs for request flow
"""
import logging
from typing import Optional, Dict, Any

from app.config import settings

logger = logging.getLogger(__name__)


def capture_exception_with_context(
    exc: Exception,
    correlation_id: Optional[str] = None,
    trace_id: Optional[str] = None,
    span_id: Optional[str] = None,
    tenant_id: Optional[str] = None,
    user_id: Optional[str] = None,
    extra: Optional[Dict[str, Any]] = None
) -> Optional[str]:
    """
    Capture exception in Sentry with full context.
    
    Args:
        exc: Exception to capture
        correlation_id: Request correlation ID
        trace_id: OpenTelemetry trace ID
        span_id: OpenTelemetry span ID
        tenant_id: Tenant ID for multi-tenancy
        user_id: User ID
        extra: Additional context
        
    Returns:
        Sentry event ID for log correlation
    """
    if not settings.SENTRY_DSN:
        return None
    
    try:
        import sentry_sdk
        
        # Set context
        with sentry_sdk.push_scope() as scope:
            # Add correlation IDs
            if correlation_id:
                scope.set_tag("correlation_id", correlation_id)
                scope.set_context("correlation", {"id": correlation_id})
            
            if trace_id:
                scope.set_tag("trace_id", trace_id)
                scope.set_context("trace", {
                    "trace_id": trace_id,
                    "span_id": span_id,
                })
            
            # Add tenant context
            if tenant_id:
                scope.set_tag("tenant_id", tenant_id)
                scope.set_user({"id": user_id or "anonymous", "tenant": tenant_id})
            elif user_id:
                scope.set_user({"id": user_id})
            
            # Add extra context
            if extra:
                for key, value in extra.items():
                    scope.set_extra(key, value)
            
            # Capture exception
            event_id = sentry_sdk.capture_exception(exc)
            return str(event_id) if event_id else None
            
    except Exception as e:
        logger.error(f"Failed to capture exception in Sentry: {e}")
        return None


def add_breadcrumb(category: str, message: str, level: str = "info", data: Optional[Dict] = None):
    """
    Add breadcrumb to Sentry for request flow tracking.
    
    Args:
        category: Breadcrumb category (e.g., "auth", "database", "api")
        message: Breadcrumb message
        level: Log level (info, warning, error)
        data: Additional data
    """
    if not settings.SENTRY_DSN:
        return
    
    try:
        import sentry_sdk
        sentry_sdk.add_breadcrumb(
            category=category,
            message=message,
            level=level,
            data=data or {}
        )
    except Exception:
        pass


def set_transaction_name(name: str):
    """Set Sentry transaction name for better grouping."""
    if not settings.SENTRY_DSN:
        return
    
    try:
        import sentry_sdk
        sentry_sdk.set_transaction_name(name)
    except Exception:
        pass
