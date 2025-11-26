from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import uuid
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from app.config import settings
from app.api.v1 import auth, ws, scm, health, users, admin
from app.middleware.tenant import tenant_middleware
from app.middleware.metrics import PrometheusMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware

# Initialize Sentry (if DSN is configured)
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[
            FastApiIntegration(),
            SqlalchemyIntegration(),
        ],
        traces_sample_rate=0.1,  # 10% of transactions for performance monitoring
        environment=settings.PROJECT_NAME,
    )

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS Middleware (first, so it applies to all responses)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security Headers Middleware
app.add_middleware(SecurityHeadersMiddleware)

# Prometheus Metrics Middleware (if enabled)
if settings.ENABLE_METRICS:
    app.add_middleware(PrometheusMiddleware)

# Rate Limiting Middleware (if Redis is available)
@app.on_event("startup")
async def startup_event():
    """Initialize rate limiting on startup"""
    try:
        from app.redis_client.client import get_redis_client
        from app.middleware.rate_limit import RateLimitMiddleware
        
        redis = await get_redis_client()
        app.add_middleware(RateLimitMiddleware, redis_client=redis)
    except Exception as e:
        # Rate limiting disabled if Redis unavailable
        print(f"Rate limiting disabled: {e}")

# Correlation ID Middleware (for request tracing)
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    """Add correlation ID to each request for tracing"""
    correlation_id = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())
    request.state.correlation_id = correlation_id
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response

# Tenant Middleware (must be after auth but before routes)
app.middleware("http")(tenant_middleware)

# Routes
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(admin.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin"])
app.include_router(scm.router, prefix=f"{settings.API_V1_STR}/scm", tags=["scm"])
app.include_router(ws.router, tags=["ws"])
app.include_router(health.router, tags=["health"])

@app.get("/")
def root():
    return {"message": "FastAPI SaaS Microservice is running"}

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
