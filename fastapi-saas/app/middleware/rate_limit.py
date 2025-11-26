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
    """
    Rate limiting middleware using Redis.
    
    Limits:
    - API endpoints: 60 requests/minute per IP
    - Login endpoint: 5 requests/minute per IP
    """
    
    def __init__(self, app, redis_client=None):
        super().__init__(app)
        self.redis_client = redis_client
        
        # Rate limits (requests per minute)
        self.default_limit = 60
        self.login_limit = 5
        
        # Endpoints with custom limits
        self.custom_limits = {
            "/api/v1/auth/login": self.login_limit,
            "/api/v1/auth/register": self.login_limit,
        }
    
    async def dispatch(self, request: Request, call_next: Callable):
        # Skip rate limiting for health checks and metrics
        if request.url.path in ["/health", "/health/live", "/health/ready", "/metrics"]:
            return await call_next(request)
        
        # Get client IP
        client_ip = request.client.host if request.client else "unknown"
        
        # Get rate limit for this endpoint
        limit = self.custom_limits.get(request.url.path, self.default_limit)
        
        # Create rate limit key
        key = f"rate_limit:{client_ip}:{request.url.path}"
        
        # Check rate limit
        if self.redis_client:
            try:
                # Get current count
                current = await self.redis_client.get(key)
                
                if current is None:
                    # First request in this window
                    await self.redis_client.setex(key, 60, 1)  # 60 seconds TTL
                else:
                    current_count = int(current)
                    
                    if current_count >= limit:
                        # Rate limit exceeded
                        raise HTTPException(
                            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                            detail=f"Rate limit exceeded. Max {limit} requests per minute."
                        )
                    
                    # Increment counter
                    await self.redis_client.incr(key)
            
            except HTTPException:
                raise
            except Exception as e:
                # If Redis fails, allow request (fail open)
                pass
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers
        if self.redis_client:
            try:
                current = await self.redis_client.get(key)
                if current:
                    remaining = max(0, limit - int(current))
                    response.headers["X-RateLimit-Limit"] = str(limit)
                    response.headers["X-RateLimit-Remaining"] = str(remaining)
                    response.headers["X-RateLimit-Reset"] = str(int(time.time()) + 60)
            except:
                pass
        
        return response


def get_rate_limiter(redis_client):
    """Factory function to create rate limiter with Redis client"""
    async def rate_limit_middleware(request: Request, call_next: Callable):
        middleware = RateLimitMiddleware(None, redis_client)
        return await middleware.dispatch(request, call_next)
    
    return rate_limit_middleware
