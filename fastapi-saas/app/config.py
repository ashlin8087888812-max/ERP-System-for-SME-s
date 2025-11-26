from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI SaaS"
    API_V1_STR: str = "/api/v1"
    
    DATABASE_URL: str
    
    # Redis Separation (Phase 3)
    REDIS_URL: str  # Legacy, kept for compatibility
    REDIS_PUBSUB_URL: Optional[str] = None  # For WebSocket pub/sub
    REDIS_CELERY_BROKER_URL: Optional[str] = None  # For Celery broker
    REDIS_CELERY_RESULT_URL: Optional[str] = None  # For Celery results
    
    # Celery (will use Redis separation if configured)
    CELERY_BROKER_URL: str
    CELERY_RESULT_BACKEND: str
    
    # JWT
    SECRET_KEY: str
    JWT_ALG: str = "HS256"
    JWT_EXP_MINUTES: int = 15
    
    # OAuth
    GOOGLE_CLIENT_ID: Optional[str] = None
    GOOGLE_CLIENT_SECRET: Optional[str] = None
    
    # Odoo
    ODOO_SERVICE_USER: Optional[str] = None
    ODOO_SERVICE_PASSWORD: Optional[str] = None
    
    # Monitoring
    SENTRY_DSN: Optional[str] = None
    ENABLE_METRICS: bool = False
    
    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_LOGIN_PER_MINUTE: int = 5

    class Config:
        env_file = ".env"
        case_sensitive = True
    
    @property
    def redis_pubsub_url(self) -> str:
        """Get Redis Pub/Sub URL with fallback to main REDIS_URL"""
        return self.REDIS_PUBSUB_URL or self.REDIS_URL
    
    @property
    def redis_celery_broker_url(self) -> str:
        """Get Redis Celery broker URL with fallback"""
        return self.REDIS_CELERY_BROKER_URL or self.CELERY_BROKER_URL
    
    @property
    def redis_celery_result_url(self) -> str:
        """Get Redis Celery result URL with fallback"""
        return self.REDIS_CELERY_RESULT_URL or self.CELERY_RESULT_BACKEND

settings = Settings()
