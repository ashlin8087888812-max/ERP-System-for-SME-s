from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import uuid
import logging
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

from app.config import settings
from app.api.v1 import (
    auth, ws, scm, health, users, admin, 
    contacts, discuss, attachments, discuss_ws, discuss_metrics,
    sales, accounting
)
from app.middleware.tenant import tenant_middleware
from app.middleware.metrics import PrometheusMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.middleware.request_logging import RequestLoggingMiddleware

# Initialize enterprise logging FIRST
from app.core.logging import logger
from app.core import tracing

logger.info(f"Starting {settings.PROJECT_NAME} in {settings.ENVIRONMENT} mode")


# Initialize Sentry (if DSN is configured)
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[
            FastApiIntegration(),
            SqlalchemyIntegration(),
        ],
        traces_sample_rate=0.1,  # 10% of transactions for performance monitoring
        environment=settings.ENVIRONMENT,  # Use proper environment name
        release=f"{settings.PROJECT_NAME}@1.0.0",
    )
    logger.info("Sentry error tracking initialized")

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Setup OpenTelemetry tracing
tracing.setup_tracing(app)

# CORS Middleware (first, so it applies to all responses)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production IMPORTANT
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request Logging Middleware (comprehensive observability)
app.add_middleware(RequestLoggingMiddleware)

# Rate Limiting Middleware
app.add_middleware(
    RateLimitMiddleware,
    redis_url=settings.REDIS_URL
)

# Security Headers Middleware
app.add_middleware(SecurityHeadersMiddleware)

# Prometheus Metrics Middleware (if enabled)
if settings.ENABLE_METRICS:
    app.add_middleware(PrometheusMiddleware)

# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Application startup tasks."""
    logger.info(f"{settings.PROJECT_NAME} starting up...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"Log Level: {settings.LOG_LEVEL}")
    logger.info(f"OpenTelemetry: {'Enabled' if settings.OTEL_ENABLED else 'Disabled'}")
    logger.info(f"Loki: {'Enabled' if settings.LOKI_ENABLED else 'Disabled'}")
    logger.info(f"Audit Logging: {'Enabled' if settings.AUDIT_LOG_ENABLED else 'Disabled'}")
    
    # Setup database logging if enabled
    if settings.LOG_SQL_QUERIES:
        try:
            from app.db.base import engine
            from app.middleware.database_logging import setup_database_logging
            setup_database_logging(engine)
        except Exception as e:
            logger.warning(f"Failed to setup database logging: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown tasks."""
    logger.info(f"{settings.PROJECT_NAME} shutting down...")

# Remove old correlation ID middleware (now handled by RequestLoggingMiddleware)
# @app.middleware("http")
# async def correlation_id_middleware(request: Request, call_next):
#     """Add correlation ID to each request for tracing"""
#     correlation_id = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())
#     request.state.correlation_id = correlation_id
#     response = await call_next(request)
#     response.headers["X-Correlation-ID"] = correlation_id
#     return response

# Tenant Middleware (must be after auth but before routes)
# app.middleware("http")(tenant_middleware)

# Routes
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(admin.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin"])
app.include_router(scm.router, prefix=f"{settings.API_V1_STR}/scm", tags=["scm"])
app.include_router(sales.router, prefix=f"{settings.API_V1_STR}/sales", tags=["sales"])
app.include_router(accounting.router, prefix=f"{settings.API_V1_STR}/accounting", tags=["accounting"])
app.include_router(contacts.router, prefix=f"{settings.API_V1_STR}/contacts", tags=["contacts"])
app.include_router(discuss.router, prefix=f"{settings.API_V1_STR}/discuss", tags=["discuss"])
app.include_router(attachments.router, prefix=f"{settings.API_V1_STR}/attachments", tags=["attachments"])
app.include_router(discuss_ws.router, prefix=settings.API_V1_STR, tags=["discuss_ws"])
app.include_router(discuss_metrics.router, prefix=f"{settings.API_V1_STR}/admin", tags=["discuss_admin"])
app.include_router(ws.router, prefix=settings.API_V1_STR, tags=["ws"])
app.include_router(health.router, tags=["health"])

@app.get("/")
def root():
    logger.debug("Root endpoint accessed")
    return {
        "message": "FastAPI SaaS Microservice is running",
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT,
    }

# Prometheus metrics endpoint
@app.get("/metrics")
def metrics():
    """Expose Prometheus metrics"""
    if not settings.ENABLE_METRICS:
        return {"error": "Metrics are disabled"}
    
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )
