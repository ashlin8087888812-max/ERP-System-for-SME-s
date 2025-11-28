"""
Prometheus metrics middleware for FastAPI.

Tracks HTTP requests, response times, and error rates.
"""
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time
from typing import Callable


# Metrics
REQUEST_COUNT = Counter(
    'fastapi_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'fastapi_request_latency_seconds',
    'Request latency in seconds',
    ['method', 'endpoint']
)

REQUEST_IN_PROGRESS = Gauge(
    'fastapi_requests_in_progress',
    'Number of requests currently being processed',
    ['method', 'endpoint']
)

CELERY_TASK_COUNT = Counter(
    'celery_tasks_total',
    'Total Celery tasks enqueued',
    ['task_name', 'status']
)

WEBSOCKET_CONNECTIONS = Gauge(
    'websocket_connections_active',
    'Number of active WebSocket connections',
    ['company_id']
)

DB_QUERY_LATENCY = Histogram(
    'database_query_latency_seconds',
    'Database query latency in seconds',
    ['query_type']
)


class PrometheusMiddleware(BaseHTTPMiddleware):
    """Middleware to track Prometheus metrics"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Skip metrics endpoint itself
        if request.url.path == "/metrics":
            return await call_next(request)
        
        method = request.method
        endpoint = request.url.path
        
        # Track in-progress requests
        REQUEST_IN_PROGRESS.labels(method=method, endpoint=endpoint).inc()
        
        # Track latency
        start_time = time.time()
        
        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            status_code = 500
            raise
        finally:
            # Record metrics
            duration = time.time() - start_time
            
            REQUEST_COUNT.labels(
                method=method,
                endpoint=endpoint,
                http_status=status_code
            ).inc()
            
            REQUEST_LATENCY.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration)
            
            REQUEST_IN_PROGRESS.labels(method=method, endpoint=endpoint).dec()
        
        return response


def track_celery_task(task_name: str, status: str):
    """Helper to track Celery task metrics"""
    CELERY_TASK_COUNT.labels(task_name=task_name, status=status).inc()


def track_websocket_connection(company_id: int, increment: bool = True):
    """Helper to track WebSocket connections"""
    if increment:
        WEBSOCKET_CONNECTIONS.labels(company_id=str(company_id)).inc()
    else:
        WEBSOCKET_CONNECTIONS.labels(company_id=str(company_id)).dec()


def track_db_query(query_type: str, duration: float):
    """Helper to track database query latency"""
    DB_QUERY_LATENCY.labels(query_type=query_type).observe(duration)
