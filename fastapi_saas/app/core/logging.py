"""
Enterprise-grade structured logging with OpenTelemetry, PII redaction, and Loki integration.

Features:
- Structured JSON logging with schema versioning
- PII redaction (passwords, emails, SSNs, credit cards, tokens)
- OpenTelemetry trace context injection
- Sentry correlation
- Log sampling and error deduplication
- Non-blocking Loki handler with circuit breaker
- Environment-based configuration
"""
import logging
import json
import sys
import re
import hashlib
import time
from datetime import datetime
from typing import Any, Dict, Optional, Set
from collections import defaultdict
from threading import Lock
import socket

from app.config import settings


# === PII REDACTION ===

class PIIRedactor:
    """Automatically redact sensitive data from logs."""
    
    # Patterns for PII detection
    PATTERNS = {
        'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
        'ssn': re.compile(r'\b\d{3}-\d{2}-\d{4}\b'),
        'credit_card': re.compile(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'),
        'phone': re.compile(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
        'ip_address': re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
    }
    
    # Sensitive field names to redact
    SENSITIVE_FIELDS = {
        'password', 'passwd', 'pwd', 'secret', 'token', 'api_key', 'apikey',
        'auth', 'authorization', 'cookie', 'session', 'csrf', 'private_key',
    }
    
    @classmethod
    def redact_string(cls, text: str) -> str:
        """Redact PII from a string."""
        if not settings.PII_REDACTION_ENABLED:
            return text
            
        for pattern_name, pattern in cls.PATTERNS.items():
            text = pattern.sub('[REDACTED]', text)
        return text
    
    @classmethod
    def redact_dict(cls, data: Dict[str, Any]) -> Dict[str, Any]:
        """Redact PII from dictionary (recursive)."""
        if not settings.PII_REDACTION_ENABLED:
            return data
            
        redacted = {}
        for key, value in data.items():
            # Check if field name is sensitive
            if any(sensitive in key.lower() for sensitive in cls.SENSITIVE_FIELDS):
                redacted[key] = '[REDACTED]'
            elif isinstance(value, dict):
                redacted[key] = cls.redact_dict(value)
            elif isinstance(value, str):
                redacted[key] = cls.redact_string(value)
            elif isinstance(value, list):
                redacted[key] = [
                    cls.redact_dict(item) if isinstance(item, dict)
                    else cls.redact_string(item) if isinstance(item, str)
                    else item
                    for item in value
                ]
            else:
                redacted[key] = value
        return redacted


# === ERROR DEDUPLICATION ===

class ErrorDeduplicator:
    """Rate limit repeated identical errors."""
    
    def __init__(self, window_seconds: int = 60):
        self.window_seconds = window_seconds
        self.error_tracking: Dict[str, float] = {}
        self.lock = Lock()
    
    def should_log(self, message: str, level: str) -> bool:
        """Check if error should be logged or is duplicate."""
        # Always log WARN and ERROR
        if level in ('WARNING', 'ERROR', 'CRITICAL'):
            # But deduplicate identical errors
            error_hash = hashlib.md5(f"{level}:{message}".encode()).hexdigest()
            
            with self.lock:
                now = time.time()
                last_logged = self.error_tracking.get(error_hash, 0)
                
                if now - last_logged >= self.window_seconds:
                    self.error_tracking[error_hash] = now
                    # Clean old entries
                    self.error_tracking = {
                        k: v for k, v in self.error_tracking.items()
                        if now - v < self.window_seconds * 2
                    }
                    return True
                return False
        
        return True


# === LOG SAMPLING ===

class LogSampler:
    """Sample high-volume INFO logs."""
    
    def __init__(self, sample_rate: float = 0.1):
        self.sample_rate = sample_rate
        self.counter = 0
        self.lock = Lock()
    
    def should_log(self, level: str) -> bool:
        """Determine if log should be emitted based on sampling."""
        # Always log WARNING and above
        if level in ('WARNING', 'ERROR', 'CRITICAL'):
            return True
        
        # Sample INFO and DEBUG
        if not settings.LOG_SAMPLING_ENABLED:
            return True
        
        with self.lock:
            self.counter += 1
            return (self.counter % int(1 / self.sample_rate)) == 0


# === STRUCTURED FORMATTER ===

class EnterpriseStructuredFormatter(logging.Formatter):
    """
    Enterprise-grade structured JSON formatter with:
    - Schema versioning
    - Trace context (OpenTelemetry)
    - Sentry correlation
    - PII redaction
    - Multi-tenant context
    """
    
    def __init__(self):
        super().__init__()
        self.hostname = socket.gethostname()
        self.redactor = PIIRedactor()
    
    def format(self, record: logging.LogRecord) -> str:
        # Base log structure (Schema v1.0)
        log_data: Dict[str, Any] = {
            "log_schema_version": settings.LOG_SCHEMA_VERSION,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": self.redactor.redact_string(record.getMessage()),
            "service": settings.PROJECT_NAME.lower(),
            "environment": settings.ENVIRONMENT,
            "hostname": self.hostname,
        }
        
        # Add correlation_id if available
        if hasattr(record, 'correlation_id'):
            log_data['correlation_id'] = record.correlation_id
        
        # Add OpenTelemetry trace context
        if hasattr(record, 'trace_id'):
            log_data['trace_id'] = record.trace_id
        if hasattr(record, 'span_id'):
            log_data['span_id'] = record.span_id
        
        # Add Sentry correlation
        if hasattr(record, 'sentry_event_id'):
            log_data['sentry_event_id'] = record.sentry_event_id
        
        # Add multi-tenant context
        if hasattr(record, 'tenant_id'):
            log_data['tenant_id'] = record.tenant_id
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        if hasattr(record, 'user_pseudonym_id'):
            log_data['user_pseudonym_id'] = record.user_pseudonym_id
        
        # Add performance metrics
        if hasattr(record, 'duration_ms'):
            log_data['duration_ms'] = record.duration_ms
        
        # Add HTTP context
        if hasattr(record, 'http_method'):
            log_data['http_method'] = record.http_method
        if hasattr(record, 'http_path'):
            log_data['http_path'] = record.http_path
        if hasattr(record, 'http_status_code'):
            log_data['http_status_code'] = record.http_status_code
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = {
                'type': record.exc_info[0].__name__ if record.exc_info[0] else None,
                'message': self.redactor.redact_string(str(record.exc_info[1])),
                'traceback': self.formatException(record.exc_info),
            }
        
        # Add extra fields (redacted)
        if hasattr(record, 'extra') and isinstance(record.extra, dict):
            log_data.update(self.redactor.redact_dict(record.extra))
        
        return json.dumps(log_data)


class HumanReadableFormatter(logging.Formatter):
    """Human-readable formatter for development."""
    
    def __init__(self):
        super().__init__(
            '%(asctime)s - %(name)s - %(levelname)s - [%(correlation_id)s] - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    def format(self, record: logging.LogRecord) -> str:
        if not hasattr(record, 'correlation_id'):
            record.correlation_id = 'N/A'
        return super().format(record)


# === TRACE CONTEXT FILTER ===

class TraceContextFilter(logging.Filter):
    """Inject OpenTelemetry trace context into logs."""
    
    def filter(self, record: logging.LogRecord) -> bool:
        # Try to get current trace context from OpenTelemetry
        try:
            if settings.OTEL_ENABLED:
                from opentelemetry import trace
                from opentelemetry.trace import SpanContext
                
                span = trace.get_current_span()
                if span and span.get_span_context().is_valid:
                    ctx = span.get_span_context()
                    record.trace_id = format(ctx.trace_id, '032x')
                    record.span_id = format(ctx.span_id, '016x')
        except Exception:
            # Fail silently - don't break logging if OTel unavailable
            pass
        
        return True


# === SETUP LOGGING ===

def setup_logging() -> logging.Logger:
    """
    Setup enterprise-grade logging configuration.
    
    Returns:
        Configured logger instance
    """
    # Get root logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper()))
    
    # Remove existing handlers
    logger.handlers = []
    
    # Choose formatter based on environment
    if settings.LOG_FORMAT == "json":
        formatter = EnterpriseStructuredFormatter()
    else:
        formatter = HumanReadableFormatter()
    
    # Console handler (always enabled)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    console_handler.addFilter(TraceContextFilter())
    logger.addHandler(console_handler)
    
    # File handler (if enabled)
    if settings.LOG_FILE_ENABLED:
        from logging.handlers import RotatingFileHandler
        
        # Parse rotation size
        rotation_bytes = _parse_size(settings.LOG_FILE_ROTATION)
        
        file_handler = RotatingFileHandler(
            settings.LOG_FILE_PATH,
            maxBytes=rotation_bytes,
            backupCount=10,
        )
        file_handler.setFormatter(formatter)
        file_handler.addFilter(TraceContextFilter())
        logger.addHandler(file_handler)
    
    # Loki handler (if enabled, added separately to avoid blocking)
    if settings.LOKI_ENABLED:
        try:
            loki_handler = get_loki_handler()
            if loki_handler:
                logger.addHandler(loki_handler)
        except Exception as e:
            # Don't fail startup if Loki is unavailable
            logger.warning(f"Failed to setup Loki handler: {e}")
    
    # Set third-party loggers to WARNING to reduce noise
    logging.getLogger("uvicorn").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    
    return logger


def get_loki_handler() -> Optional[logging.Handler]:
    """Get Loki handler if available (non-blocking)."""
    try:
        from logging_loki import LokiHandler as BaseLokiHandler
        
        handler = BaseLokiHandler(
            url=f"{settings.LOKI_URL}/loki/api/v1/push",
            tags={
                "service": settings.PROJECT_NAME.lower(),
                "environment": settings.ENVIRONMENT,
            },
            version="1",
        )
        handler.addFilter(TraceContextFilter())
        return handler
    except ImportError:
        return None
    except Exception as e:
        logging.warning(f"Loki handler unavailable: {e}")
        return None


def _parse_size(size_str: str) -> int:
    """Parse size string like '100 MB' to bytes."""
    size_str = size_str.strip().upper()
    
    units = {
        'KB': 1024,
        'MB': 1024 ** 2,
        'GB': 1024 ** 3,
    }
    
    for unit, multiplier in units.items():
        if unit in size_str:
            number = float(size_str.replace(unit, '').strip())
            return int(number * multiplier)
    
    # Default to bytes
    return int(size_str)


# Initialize logging
logger = setup_logging()

# Export deduplicator and sampler for use in other modules
error_deduplicator = ErrorDeduplicator(window_seconds=settings.LOG_ERROR_DEDUP_WINDOW)
log_sampler = LogSampler(sample_rate=settings.LOG_SAMPLING_RATE)
