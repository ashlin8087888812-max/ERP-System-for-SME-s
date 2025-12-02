"""
Database query logging and performance tracking.

Features:
- Log slow queries (configurable threshold)
- Track query execution time
- Parameter redaction for security
- Integration with OpenTelemetry spans
- Connection pool monitoring
"""
import logging
import time
from typing import Any

from sqlalchemy import event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.config import settings
from app.core.logging import PIIRedactor

logger = logging.getLogger(__name__)

# Query performance tracking
SLOW_QUERY_THRESHOLD_MS = 100  # Log queries slower than this


def setup_database_logging(engine: Engine):
    """
    Setup database query logging with SQLAlchemy events.
    
    Args:
        engine: SQLAlchemy engine instance
    """
    if not settings.LOG_SQL_QUERIES:
        logger.info("SQL query logging disabled")
        return
    
    redactor = PIIRedactor()
    
    @event.listens_for(engine, "before_cursor_execute")
    def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
        """Track query start time."""
        context._query_start_time = time.time()
    
    @event.listens_for(engine, "after_cursor_execute")
    def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
        """Log query execution time."""
        if not hasattr(context, '_query_start_time'):
            return
        
        # Calculate duration
        duration_ms = (time.time() - context._query_start_time) * 1000
        
        # Only log slow queries or if debug mode
        if duration_ms >= SLOW_QUERY_THRESHOLD_MS or settings.LOG_LEVEL == "DEBUG":
            # Redact sensitive parameters
            safe_params = redactor.redact_dict(parameters) if isinstance(parameters, dict) else parameters
            
            log_data = {
                "query_duration_ms": round(duration_ms, 2),
                "query_statement": statement[:500],  # Truncate long queries
                "query_parameters": str(safe_params)[:200] if safe_params else None,
                "is_slow_query": duration_ms >= SLOW_QUERY_THRESHOLD_MS,
            }
            
            # Add to OpenTelemetry span if available
            if settings.OTEL_ENABLED:
                try:
                    from app.core.tracing import add_span_event
                    add_span_event("database.query", log_data)
                except Exception:
                    pass
            
            # Log based on performance
            if duration_ms >= SLOW_QUERY_THRESHOLD_MS:
                logger.warning(f"Slow query detected ({duration_ms:.2f}ms)", extra=log_data)
            else:
                logger.debug(f"Database query ({duration_ms:.2f}ms)", extra=log_data)
    
    @event.listens_for(engine, "handle_error")
    def handle_error(exception_context):
        """Log database errors with context."""
        logger.error(
            f"Database error: {exception_context.original_exception}",
            extra={
                "query_statement": exception_context.statement[:500] if exception_context.statement else None,
                "exception_type": type(exception_context.original_exception).__name__,
            },
            exc_info=True
        )
    
    logger.info("Database query logging enabled (threshold: {}ms)".format(SLOW_QUERY_THRESHOLD_MS))


def log_connection_pool_stats(engine: Engine):
    """Log connection pool statistics."""
    try:
        pool = engine.pool
        logger.info(
            "Connection pool stats",
            extra={
                "pool_size": pool.size(),
                "checked_in": pool.checkedin(),
                "checked_out": pool.checkedout(),
                "overflow": pool.overflow(),
            }
        )
    except Exception as e:
        logger.debug(f"Could not get pool stats: {e}")
