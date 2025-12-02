#request_logging.py
"""
Request/Response logging middleware with comprehensive observability.

Features:
- Automatic correlation_id injection
- OpenTelemetry trace context extraction
- Request/response timing and size tracking
- PII-safe header and body logging
- Integration with Prometheus metrics
- Sentry error correlation
"""
import logging
import time
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.datastructures import Headers

from app.config import settings
from app.core.logging import PIIRedactor

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Comprehensive request/response logging middleware.
    
    Logs:
    - HTTP method, path, status code
    - Request/response timing and sizes
    - Correlation ID (auto-generated or from header)
    - Trace ID and Span ID (from OpenTelemetry)
    - Tenant and user context
    """
    
    def __init__(self, app):
        super().__init__(app)
        self.redactor = PIIRedactor()
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Skipping logging for Prometheus metrics endpoint to avoid noisy logs
        if request.url.path == "/metrics":
            return await call_next(request)
        # Generate or extract correlation ID
        correlation_id = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())
        request.state.correlation_id = correlation_id
        
        # Get trace context (if OTel enabled)
        trace_id = None
        span_id = None
        if settings.OTEL_ENABLED:
            try:
                from app.core.tracing import get_current_trace_id, get_current_span_id
                trace_id = get_current_trace_id()
                span_id = get_current_span_id()
            except Exception:
                pass
        
        # Extract tenant/user context (if available)
        tenant_id = getattr(request.state, 'tenant_id', None)
        user_id = getattr(request.state, 'user_id', None)
        
        # Track request start time
        start_time = time.time()
        
        # Get request size
        request_size = request.headers.get("content-length", 0)
        
        # Log request body if enabled (dev only)
        request_body = None
        if settings.LOG_REQUEST_BODY and settings.ENVIRONMENT == "development":
            try:
                request_body = await request.body()
                # Decode for logging
                request_body = request_body.decode('utf-8')[:500]  # Limit size
            except Exception:
                request_body = None
        
        # Process request
        response = await call_next(request)
        
        # Calculate duration
        duration_ms = (time.time() - start_time) * 1000
        
        # Get response size
        response_size = response.headers.get("content-length", 0)
        
        # Log request completion
        log_data = {
            "correlation_id": correlation_id,
            "trace_id": trace_id,
            "span_id": span_id,
            "tenant_id": tenant_id,
            "user_id": user_id,
            "http_method": request.method,
            "http_path": request.url.path,
            "http_query": str(request.url.query) if request.url.query else None,
            "http_status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "request_size_bytes": int(request_size),
            "response_size_bytes": int(response_size),
            "client_ip": request.client.host if request.client else None,
            "user_agent": request.headers.get("user-agent"),
        }
        
        # Add sensitive=false headers
        if not settings.LOG_SENSITIVE_HEADERS:
            log_data["headers"] = self._redact_headers(dict(request.headers))
        
        # Add request body if enabled
        if request_body:
            log_data["request_body"] = self.redactor.redact_string(request_body)
        
        # Log with appropriate level based on status code
        log_level = self._get_log_level(response.status_code)
        logger.log(
            log_level,
            f"HTTP {request.method} {request.url.path} -> {response.status_code}",
            extra=log_data
        )
        
        # Add correlation ID to response headers
        response.headers["X-Correlation-ID"] = correlation_id
        
        # Add trace ID to response headers (for client-side debugging)
        if trace_id:
            response.headers["X-Trace-ID"] = trace_id
        
        return response
    
    def _get_log_level(self, status_code: int) -> int:
        """Determine log level based on HTTP status code."""
        if status_code >= 500:
            return logging.ERROR
        elif status_code >= 400:
            return logging.WARNING
        else:
            return logging.INFO
    
    def _redact_headers(self, headers: dict) -> dict:
        """Redact sensitive headers."""
        redacted = {}
        sensitive_headers = {
            'authorization', 'cookie', 'x-api-key', 'x-auth-token',
            'set-cookie', 'proxy-authorization'
        }
        
        for key, value in headers.items():
            if key.lower() in sensitive_headers:
                redacted[key] = '[REDACTED]'
            else:
                redacted[key] = value
        
        return redacted
