import redis.asyncio as redis
from app.config import settings
from typing import Optional

class RedisManager:
    _client: Optional[redis.Redis] = None

    @classmethod
    def get_client(cls) -> redis.Redis:
        if cls._client is None:
            cls._client = redis.from_url(
                settings.REDIS_URL, 
                encoding="utf-8", 
                decode_responses=True,
                socket_keepalive=True,
                health_check_interval=30
            )
        return cls._client

    @classmethod
    async def close(cls):
        if cls._client:
            await cls._client.close()
            cls._client = None

async def get_redis_client() -> redis.Redis:
    return RedisManager.get_client()
