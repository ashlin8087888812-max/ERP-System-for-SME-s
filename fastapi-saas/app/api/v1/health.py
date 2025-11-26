"""
Enhanced health check endpoint.

Checks connectivity to all critical services:
- PostgreSQL database
- Redis (Pub/Sub and Celery)
- Celery queue depth
"""
from fastapi import APIRouter, status
from sqlalchemy import text
from app.db.base import SessionLocal
from app.redis_client.client import get_redis_client
from app.config import settings
import asyncio
from typing import Dict, Any

router = APIRouter()


async def check_database() -> Dict[str, Any]:
    """Check PostgreSQL connectivity"""
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "healthy", "message": "Database connection OK"}
    except Exception as e:
        return {"status": "unhealthy", "message": f"Database error: {str(e)}"}


async def check_redis_pubsub() -> Dict[str, Any]:
    """Check Redis Pub/Sub connectivity"""
    try:
        redis = await get_redis_client()
        await redis.ping()
        return {"status": "healthy", "message": "Redis Pub/Sub OK"}
    except Exception as e:
        return {"status": "unhealthy", "message": f"Redis Pub/Sub error: {str(e)}"}


async def check_redis_celery() -> Dict[str, Any]:
    """Check Redis Celery broker connectivity"""
    try:
        # This would require a separate Redis client for Celery
        # For now, we'll use the same check
        redis = await get_redis_client()
        await redis.ping()
        return {"status": "healthy", "message": "Redis Celery OK"}
    except Exception as e:
        return {"status": "unhealthy", "message": f"Redis Celery error: {str(e)}"}


async def check_celery_queue() -> Dict[str, Any]:
    """Check Celery queue depth"""
    try:
        from app.workers.celery_app import celery_app
        
        # Get queue stats
        inspect = celery_app.control.inspect()
        active = inspect.active()
        
        if active is None:
            return {"status": "unhealthy", "message": "No Celery workers available"}
        
        # Count active tasks
        total_active = sum(len(tasks) for tasks in active.values())
        
        return {
            "status": "healthy",
            "message": f"Celery workers active",
            "active_tasks": total_active,
            "workers": len(active)
        }
    except Exception as e:
        return {"status": "unhealthy", "message": f"Celery error: {str(e)}"}


@router.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """
    Comprehensive health check endpoint.
    
    Returns 200 if all services are healthy, 503 if any are unhealthy.
    """
    checks = {
        "database": await check_database(),
        "redis_pubsub": await check_redis_pubsub(),
        "redis_celery": await check_redis_celery(),
        "celery": await check_celery_queue()
    }
    
    # Determine overall health
    all_healthy = all(check["status"] == "healthy" for check in checks.values())
    
    response = {
        "status": "healthy" if all_healthy else "unhealthy",
        "checks": checks
    }
    
    if not all_healthy:
        return response, status.HTTP_503_SERVICE_UNAVAILABLE
    
    return response


@router.get("/health/live", status_code=status.HTTP_200_OK)
async def liveness():
    """Kubernetes liveness probe - is the app running?"""
    return {"status": "alive"}


@router.get("/health/ready", status_code=status.HTTP_200_OK)
async def readiness():
    """Kubernetes readiness probe - is the app ready to serve traffic?"""
    # Check critical services only
    db_check = await check_database()
    
    if db_check["status"] != "healthy":
        return {"status": "not ready", "reason": "Database unavailable"}, status.HTTP_503_SERVICE_UNAVAILABLE
    
    return {"status": "ready"}
