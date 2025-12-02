"""
OpenTelemetry distributed tracing integration.

Features:
- Automatic FastAPI instrumentation
- SQLAlchemy and Redis tracing
- Trace context propagation
- Integration with logging (trace_id in logs)
- Graceful failure (non-blocking)
- Multiple exporters (Jaeger, OTLP)
"""
import logging
from typing import Dict, Optional, Callable
from contextlib import contextmanager

from app.config import settings

logger = logging.getLogger(__name__)

# OpenTelemetry imports (conditional)
tracer = None
trace_api = None

if settings.OTEL_ENABLED:
    try:
        from opentelemetry import trace
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.sampling import ParentBasedTraceIdRatio
        from opentelemetry.sdk.resources import Resource, SERVICE_NAME
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.exporter.jaeger.thrift import JaegerExporter
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
        from opentelemetry.instrumentation.redis import RedisInstrumentor
        
        trace_api = trace
    except ImportError as e:
        logger.warning(f"OpenTelemetry not available: {e}")
        settings.OTEL_ENABLED = False


def setup_tracing(app):
    """
    Setup OpenTelemetry tracing for FastAPI application.
    
    Args:
        app: FastAPI application instance
    """
    if not settings.OTEL_ENABLED or not trace_api:
        logger.info("OpenTelemetry tracing disabled")
        return
    
    try:
        # Create resource with service name
        resource = Resource(attributes={
            SERVICE_NAME: settings.OTEL_SERVICE_NAME,
            "environment": settings.ENVIRONMENT,
            "service.version": "1.0.0",
        })
        
        # Create tracer provider with sampling
        sampler = ParentBasedTraceIdRatio(settings.OTEL_TRACES_SAMPLER_ARG)
        provider = TracerProvider(resource=resource, sampler=sampler)
        
        # Add exporters
        _add_exporters(provider)
        
        # Set global tracer provider
        trace_api.set_tracer_provider(provider)
        
        # Instrument FastAPI
        FastAPIInstrumentor.instrument_app(app)
        
        # Instrument SQLAlchemy (if available)
        try:
            SQLAlchemyInstrumentor().instrument()
        except Exception as e:
            logger.warning(f"Failed to instrument SQLAlchemy: {e}")
        
        # Instrument Redis (if available)
        try:
            RedisInstrumentor().instrument()
        except Exception as e:
            logger.warning(f"Failed to instrument Redis: {e}")
        
        # Create global tracer
        global tracer
        tracer = trace_api.get_tracer(__name__)
        
        logger.info(f"OpenTelemetry tracing enabled (sampling: {settings.OTEL_TRACES_SAMPLER_ARG})")
        
    except Exception as e:
        if settings.OTEL_FAIL_SILENTLY:
            logger.warning(f"Failed to setup tracing (continuing anyway): {e}")
        else:
            raise


def _add_exporters(provider: 'TracerProvider'):
    """Add span exporters to provider."""
    
    # OTLP exporter (gRPC)
    try:
        otlp_exporter = OTLPSpanExporter(
            endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
            insecure=True,  # Use TLS in production
        )
        provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
        logger.info(f"OTLP exporter configured: {settings.OTEL_EXPORTER_OTLP_ENDPOINT}")
    except Exception as e:
        logger.warning(f"OTLP exporter failed: {e}")
    
    # Jaeger exporter (optional, for local development)
    if settings.ENVIRONMENT == "development":
        try:
            jaeger_exporter = JaegerExporter(
                agent_host_name="localhost",
                agent_port=6831,
            )
            provider.add_span_processor(BatchSpanProcessor(jaeger_exporter))
            logger.info("Jaeger exporter configured")
        except Exception as e:
            logger.debug(f"Jaeger exporter not available: {e}")


@contextmanager
def create_span(name: str, attributes: Optional[Dict] = None):
    """
    Create a custom span for business logic tracing.
    
    Args:
        name: Span name
        attributes: Optional span attributes
        
    Yields:
        Span context (or None if tracing disabled)
    """
    if not settings.OTEL_ENABLED or not tracer:
        yield None
        return
    
    try:
        with tracer.start_as_current_span(name) as span:
            if attributes:
                for key, value in attributes.items():
                    span.set_attribute(key, value)
            yield span
    except Exception as e:
        if settings.OTEL_FAIL_SILENTLY:
            logger.debug(f"Span creation failed (continuing): {e}")
            yield None
        else:
            raise


def get_current_trace_id() -> Optional[str]:
    """Get current trace ID as hex string."""
    if not settings.OTEL_ENABLED or not trace_api:
        return None
    
    try:
        span = trace_api.get_current_span()
        if span and span.get_span_context().is_valid:
            ctx = span.get_span_context()
            return format(ctx.trace_id, '032x')
    except Exception:
        pass
    
    return None


def get_current_span_id() -> Optional[str]:
    """Get current span ID as hex string."""
    if not settings.OTEL_ENABLED or not trace_api:
        return None
    
    try:
        span = trace_api.get_current_span()
        if span and span.get_span_context().is_valid:
            ctx = span.get_span_context()
            return format(ctx.span_id, '016x')
    except Exception:
        pass
    
    return None


def add_span_event(event: str, attributes: Optional[Dict] = None):
    """
    Add an event to the current span.
    
    Args:
        event: Event name
        attributes: Optional event attributes
    """
    if not settings.OTEL_ENABLED or not trace_api:
        return
    
    try:
        span = trace_api.get_current_span()
        if span and span.get_span_context().is_valid:
            span.add_event(event, attributes=attributes or {})
    except Exception as e:
        if not settings.OTEL_FAIL_SILENTLY:
            raise
        logger.debug(f"Failed to add span event: {e}")


def add_span_attributes(attributes: Dict):
    """
    Add attributes to the current span.
    
    Args:
        attributes: Attributes to add
    """
    if not settings.OTEL_ENABLED or not trace_api:
        return
    
    try:
        span = trace_api.get_current_span()
        if span and span.get_span_context().is_valid:
            for key, value in attributes.items():
                span.set_attribute(key, value)
    except Exception as e:
        if not settings.OTEL_FAIL_SILENTLY:
            raise
        logger.debug(f"Failed to add span attributes: {e}")


def capture_exception_with_trace(exc: Exception) -> Optional[str]:
    """
    Capture exception in current span and return Sentry event ID.
    
    Args:
        exc: Exception to capture
        
    Returns:
        Sentry event ID (if Sentry enabled), otherwise None
    """
    # Add exception to span
    if settings.OTEL_ENABLED and trace_api:
        try:
            span = trace_api.get_current_span()
            if span and span.get_span_context().is_valid:
                span.record_exception(exc)
                span.set_status(trace_api.Status(trace_api.StatusCode.ERROR))
        except Exception:
            pass
    
    # Capture in Sentry with trace context
    if settings.SENTRY_DSN:
        try:
            import sentry_sdk
            from app.core.sentry_integration import capture_exception_with_context
            return capture_exception_with_context(exc)
        except Exception:
            pass
    
    return None
