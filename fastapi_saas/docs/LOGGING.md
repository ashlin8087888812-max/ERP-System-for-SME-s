# Enterprise Logging - Environment Variables

Add these to your `.env` file:

```env
# === LOGGING CONFIGURATION ===

# Core Settings
ENVIRONMENT=development  # development, staging, production
LOG_LEVEL=INFO
LOG_FORMAT=json  # json or text

# File Logging
LOG_FILE_ENABLED=true
LOG_FILE_PATH=./logs/app.log
LOG_FILE_ROTATION=100 MB
LOG_FILE_RETENTION=30 days
LOG_FILE_COMPRESSION=gz

# Grafana Loki (optional - disable for lightweight mode)
LOKI_ENABLED=false
LOKI_URL=http://localhost:3100
LOKI_BATCH_SIZE=100
LOKI_BATCH_INTERVAL=1.0
LOKI_MAX_RETRIES=3
LOKI_BUFFER_SIZE=10000
LOKI_TIMEOUT_SECONDS=2.0

# OpenTelemetry Tracing (optional - disable for lightweight mode)
OTEL_ENABLED=false
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=syncerity-api
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1  # 10% sampling
OTEL_FAIL_SILENTLY=true

# Audit Logging & WORM
AUDIT_LOG_ENABLED=true
AUDIT_LOG_STORAGE=file  # file, s3, or database
AUDIT_LOG_PATH=./logs/audit/
AUDIT_LOG_WORM_ENABLED=false
AUDIT_LOG_S3_BUCKET=  # Only if using S3
AUDIT_LOG_RETENTION_DAYS=2555  # 7 years for compliance

# SIEM Integration (optional - enterprise mode only)
SIEM_ENABLED=false
SIEM_TYPE=webhook  # webhook, syslog, splunk, elasticsearch
SIEM_ENDPOINT=
SIEM_API_KEY=
SIEM_ASYNC_ONLY=true

# Privacy & Compliance
PII_REDACTION_ENABLED=true
LOG_REQUEST_BODY=false  # true only in development
LOG_RESPONSE_BODY=false
LOG_SQL_QUERIES=false
LOG_SENSITIVE_HEADERS=false
USE_PSEUDONYMOUS_IDS=true

# Log Schema & Versioning
LOG_SCHEMA_VERSION=1.0

# Log Sampling & Rate Limiting
LOG_SAMPLING_ENABLED=false
LOG_SAMPLING_RATE=0.1
LOG_ERROR_DEDUP_WINDOW=60
```

## Quick Start Guides

### Lightweight Mode (Early-Stage)
```env
ENVIRONMENT=development
LOG_LEVEL=DEBUG
LOG_FORMAT=text
LOG_REQUEST_BODY=true
LOG_SQL_QUERIES=true
OTEL_ENABLED=false
LOKI_ENABLED=false
SIEM_ENABLED=false
PII_REDACTION_ENABLED=false  # Dev only
```

**Start app only:**
```bash
uvicorn app.main:app --reload
```

### Standard Mode (Production)
```env
ENVIRONMENT=production
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_REQUEST_BODY=false
LOG_SQL_QUERIES=false
LOG_SAMPLING_ENABLED=true
OTEL_ENABLED=true
OTEL_TRACES_SAMPLER_ARG=0.1
LOKI_ENABLED=true
PII_REDACTION_ENABLED=true
USE_PSEUDONYMOUS_IDS=true
```

**Start with monitoring stack:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

**Access:**
- Grafana: http://localhost:3000 (admin/admin)
- Jaeger: http://localhost:16686
- Loki: http://localhost:3100

### Enterprise Mode (Regulated)
```env
ENVIRONMENT=production
LOG_LEVEL=INFO
LOG_FORMAT=json
OTEL_ENABLED=true
OTEL_TRACES_SAMPLER_ARG=0.05  # 5% sampling
LOKI_ENABLED=true
AUDIT_LOG_WORM_ENABLED=true
AUDIT_LOG_STORAGE=s3
AUDIT_LOG_S3_BUCKET=my-compliance-bucket
SIEM_ENABLED=true
SIEM_TYPE=webhook
SIEM_ENDPOINT=https://siem.company.com/api/events
PII_REDACTION_ENABLED=true
USE_PSEUDONYMOUS_IDS=true
```

## Operational Requirements

### Time Synchronization
**CRITICAL**: All nodes must run NTP/chrony to ensure accurate timestamps.

```bash
# Check NTP status
ntpstat

# Or for chrony
chronyc tracking
```

### Secrets Management
**NEVER** hardcode credentials. Use:
- Environment variables (development)
- Kubernetes Secrets (production)
- AWS Secrets Manager / HashiCorp Vault (enterprise)

### Resource Monitoring
Monitor logging overhead:
- CPU: <5-10% under nominal load
- Memory: Monitor buffer sizes
- Network: Loki batch compression enabled

## Verification

### Test Logging
```bash
# Make a request
curl http://localhost:8000/api/v1/health

# Check logs
tail -f logs/app.log

# Check audit logs
tail -f logs/audit/audit_$(date +%Y-%m-%d).jsonl
```

### Query Loki
```bash
# In Grafana, use LogQL:
{service="syncerity-api", environment="production"} 
| json 
| correlation_id="abc-123"
```

### View Traces
Open Jaeger UI: http://localhost:16686
Search for service: `syncerity-api`

## Troubleshooting

### Loki not receiving logs
```bash
# Check Promtail logs
docker-compose logs promtail

# Test Loki endpoint
curl http://localhost:3100/ready
```

### OpenTelemetry not exporting
Check `OTEL_FAIL_SILENTLY=true` - traces will be skipped but requests continue

### High log volume
Enable sampling:
```env
LOG_SAMPLING_ENABLED=true
LOG_SAMPLING_RATE=0.1  # Keep 10% of INFO logs
```
