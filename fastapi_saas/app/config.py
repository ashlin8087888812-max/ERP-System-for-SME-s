from pydantic_settings import BaseSettings
from typing import Optional, Dict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Gestace"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"  # development, staging, production
    
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
    
    # Refresh Token (Enterprise-grade stateful tokens)
    REFRESH_TOKEN_EXP_DAYS: int = 30
    REFRESH_TOKEN_ROTATION_ENABLED: bool = True
    REFRESH_TOKEN_CLEANUP_INTERVAL_HOURS: int = 24
    
    # OAuth
    GOOGLE_CLIENT_ID: Optional[str] = None
    GOOGLE_CLIENT_SECRET: Optional[str] = None
    
    # Odoo
    ODOO_HOST: str = "http://34.56.20.178:8068"
    ODOO_SERVICE_USER: Optional[str] = None
    ODOO_SERVICE_PASSWORD: Optional[str] = None
    
    # Monitoring
    SENTRY_DSN: Optional[str] = None
    ENABLE_METRICS: bool = False
    
    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_LOGIN_PER_MINUTE: int = 5
    
    # === LOGGING CONFIGURATION ===
    
    # Logging Core
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # json, text, or cef (for SIEM)
    
    # File Logging
    LOG_FILE_ENABLED: bool = True
    LOG_FILE_PATH: str = "./logs/app.log"
    LOG_FILE_ROTATION: str = "100 MB"
    LOG_FILE_RETENTION: str = "30 days"
    LOG_FILE_COMPRESSION: str = "gz"
    
    # Grafana Loki
    LOKI_ENABLED: bool = False
    LOKI_URL: str = "http://localhost:3100"
    LOKI_BATCH_SIZE: int = 100
    LOKI_BATCH_INTERVAL: float = 1.0
    LOKI_MAX_RETRIES: int = 3
    LOKI_BUFFER_SIZE: int = 10000
    LOKI_TIMEOUT_SECONDS: float = 2.0
    
    # OpenTelemetry
    OTEL_ENABLED: bool = False
    OTEL_EXPORTER_OTLP_ENDPOINT: str = "http://localhost:4317"
    OTEL_SERVICE_NAME: str = "gestace-api"
    OTEL_TRACES_SAMPLER: str = "parentbased_traceidratio"
    OTEL_TRACES_SAMPLER_ARG: float = 0.1  # 10% sampling
    OTEL_FAIL_SILENTLY: bool = True
    
    # Audit Logging & WORM
    AUDIT_LOG_ENABLED: bool = True
    AUDIT_LOG_STORAGE: str = "file"  # file, s3, or database
    AUDIT_LOG_PATH: str = "./logs/audit/"
    AUDIT_LOG_WORM_ENABLED: bool = False
    AUDIT_LOG_S3_BUCKET: Optional[str] = None
    AUDIT_LOG_RETENTION_DAYS: int = 2555  # 7 years for compliance
    
    # SIEM Integration
    SIEM_ENABLED: bool = False
    SIEM_TYPE: str = "webhook"  # webhook, syslog, splunk, elasticsearch
    SIEM_ENDPOINT: Optional[str] = None
    SIEM_API_KEY: Optional[str] = None
    SIEM_ASYNC_ONLY: bool = True
    
    # Privacy & Compliance
    PII_REDACTION_ENABLED: bool = True
    LOG_REQUEST_BODY: bool = False
    LOG_RESPONSE_BODY: bool = False
    LOG_SQL_QUERIES: bool = False
    LOG_SENSITIVE_HEADERS: bool = False
    USE_PSEUDONYMOUS_IDS: bool = True
    
    # Log Schema & Versioning
    LOG_SCHEMA_VERSION: str = "1.0"
    
    # Log Sampling & Rate Limiting
    LOG_SAMPLING_ENABLED: bool = False
    LOG_SAMPLING_RATE: float = 0.1
    LOG_ERROR_DEDUP_WINDOW: int = 60

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
