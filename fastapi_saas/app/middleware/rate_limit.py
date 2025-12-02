"""
Rate limiting middleware using Redis.

Prevents abuse by limiting requests per IP address.
"""
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from typing import Callable
import time
import hashlib


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, redis_url: str | None = None):
        super().__init__(app)
        self.redis_url = redis_url
        self.redis = None

        """
        Rate limiting middleware using Redis.
    
        Limits:
        - API endpoints: 60 requests/minute per IP
        - Login endpoint: 5 requests/minute per IP
        """
        # Rate limits (requests per minute)
        self.default_limit = 60
        self.login_limit = 5
        
        # Endpoints with custom limits (prefix matching)
        self.custom_limits = {
            "/api/v1/auth/login": self.login_limit,
            "/api/v1/auth/register": self.login_limit,
            "/api/v1/contacts": 120,  # Higher limit for contacts endpoint
        }
    
    async def dispatch(self, request: Request, call_next: Callable):
        # 1. Skip health & metrics
        if request.url.path in ["/health", "/health/live", "/health/ready", "/metrics"]:
            return await call_next(request)

        # 2. Connect to Redis once
        if self.redis is None and self.redis_url:
            try:
                import redis.asyncio as redis
                self.redis = redis.from_url(self.redis_url)
            except Exception:
                self.redis = None  # fail open

        # 3. If Redis is unavailable, allow request
        if self.redis is None:
            return await call_next(request)

        # 4. Get IP
        client_ip = request.client.host if request.client else "unknown"

        # 5. Decide limit using prefix matching
        limit = self.default_limit
        for path_prefix, path_limit in self.custom_limits.items():
            if request.url.path.startswith(path_prefix):
                limit = path_limit
                break

        # 6. Build Redis key
        key = f"rate_limit:{client_ip}:{request.url.path}"

        # 7. Check counter
        current = await self.redis.get(key)

        if current is None:
            await self.redis.setex(key, 60, 1)
        else:
            current = int(current)
            if current >= limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests"
                )
            await self.redis.incr(key)

        # 8. Call the actual API
        response = await call_next(request)

        # 9. Add headers
        remaining = max(0, limit - int(await self.redis.get(key)))
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)

        return response


# def get_rate_limiter(redis_client):
#     """Factory function to create rate limiter with Redis client"""
#     async def rate_limit_middleware(request: Request, call_next: Callable):
#         middleware = RateLimitMiddleware(None, redis_client)
#         return await middleware.dispatch(request, call_next)
    
#     return rate_limit_middleware
