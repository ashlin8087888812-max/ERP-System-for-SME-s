import json
import logging
from typing import Any, Optional, List
from app.redis_client.client import get_redis_client

logger = logging.getLogger(__name__)

class DiscussCache:
    """
    Redis caching layer for Discuss module with:
    - SETNX Stampede Protection
    - JSON Serialization
    - Tenant-aware key namespacing
    """
    
    @staticmethod
    def _gen_key(company_id: int, model: str, identifier: Any) -> str:
        return f"cache:v1:{company_id}:{model}:{identifier}"

    @classmethod
    async def get(cls, company_id: int, model: str, identifier: Any) -> Optional[Any]:
        redis = await get_redis_client()
        key = cls._gen_key(company_id, model, identifier)
        data = await redis.get(key)
        if data:
            return json.loads(data)
        return None

    @classmethod
    async def set(
        cls, 
        company_id: int, 
        model: str, 
        identifier: Any, 
        value: Any, 
        ttl: int = 300 # 5 min default
    ):
        redis = await get_redis_client()
        key = cls._gen_key(company_id, model, identifier)
        await redis.setex(key, ttl, json.dumps(value))

    @classmethod
    async def delete(cls, company_id: int, model: str, identifier: Any):
        redis = await get_redis_client()
        key = cls._gen_key(company_id, model, identifier)
        await redis.delete(key)

    @classmethod
    async def lock_and_get(cls, company_id: int, model: str, identifier: Any, ttl: int = 10):
        """Implement locking for stampede protection if needed"""
        redis = await get_redis_client()
        lock_key = f"lock:{cls._gen_key(company_id, model, identifier)}"
        # Simple lock implementation
        return await redis.set(lock_key, "1", ex=ttl, nx=True)

discuss_cache = DiscussCache()
