"""
Tenant Quotas & Rate Control.

Prevents one tenant from overloading the system.
"""
from typing import Dict, Optional
from fastapi import HTTPException, status
from app.redis_client.client import get_redis_client


class TenantQuotas:
    """Manage per-tenant quotas and limits"""
    
    # Default quotas (can be overridden per tenant)
    DEFAULT_QUOTAS = {
        "max_api_calls_per_minute": 1000,
        "max_events_per_minute": 100,
        "max_background_tasks_per_hour": 500,
        "max_storage_mb": 10000,  # 10GB
        "max_users": 100,
        "max_concurrent_connections": 50,
    }
    
    @staticmethod
    async def get_quota(company_id: int, quota_name: str) -> int:
        """Get quota value for tenant"""
        redis = await get_redis_client()
        
        # Check for custom quota
        key = f"quota:{company_id}:{quota_name}"
        custom_quota = await redis.get(key)
        
        if custom_quota:
            return int(custom_quota)
        
        # Return default
        return TenantQuotas.DEFAULT_QUOTAS.get(quota_name, 0)
    
    @staticmethod
    async def set_quota(company_id: int, quota_name: str, value: int):
        """Set custom quota for tenant"""
        redis = await get_redis_client()
        key = f"quota:{company_id}:{quota_name}"
        await redis.set(key, value)
    
    @staticmethod
    async def check_quota(company_id: int, quota_name: str, increment: int = 1) -> bool:
        """
        Check if tenant is within quota.
        
        Returns True if within quota, raises HTTPException if exceeded.
        """
        redis = await get_redis_client()
        
        # Get quota limit
        limit = await TenantQuotas.get_quota(company_id, quota_name)
        
        # Get current usage
        usage_key = f"usage:{company_id}:{quota_name}"
        current_usage = await redis.get(usage_key)
        current_usage = int(current_usage) if current_usage else 0
        
        # Check if would exceed
        if current_usage + increment > limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Tenant quota exceeded for {quota_name}. Limit: {limit}, Current: {current_usage}"
            )
        
        # Increment usage
        await redis.incr(usage_key)
        
        # Set TTL based on quota type
        if "per_minute" in quota_name:
            await redis.expire(usage_key, 60)
        elif "per_hour" in quota_name:
            await redis.expire(usage_key, 3600)
        elif "per_day" in quota_name:
            await redis.expire(usage_key, 86400)
        
        return True
    
    @staticmethod
    async def get_usage(company_id: int, quota_name: str) -> Dict[str, int]:
        """Get current usage and limit for quota"""
        redis = await get_redis_client()
        
        limit = await TenantQuotas.get_quota(company_id, quota_name)
        
        usage_key = f"usage:{company_id}:{quota_name}"
        current_usage = await redis.get(usage_key)
        current_usage = int(current_usage) if current_usage else 0
        
        return {
            "limit": limit,
            "current": current_usage,
            "remaining": max(0, limit - current_usage),
            "percentage": (current_usage / limit * 100) if limit > 0 else 0
        }
