# Production Deployment Guide

## Overview

This guide covers deploying the FastAPI-SaaS backend to production environments.

---

## Infrastructure Requirements

### **Minimum Requirements**

| Component | Specification |
|-----------|--------------|
| **Application Server** | 2 vCPU, 4GB RAM |
| **PostgreSQL** | 2 vCPU, 8GB RAM, 100GB SSD |
| **Redis (Pub/Sub)** | 1 vCPU, 1GB RAM |
| **Redis (Celery)** | 1 vCPU, 2GB RAM |
| **Celery Workers** | 2 vCPU, 4GB RAM (per worker) |

### **Recommended Production**

| Component | Specification |
|-----------|--------------|
| **Application Server** | 4 vCPU, 8GB RAM (2+ instances) |
| **PostgreSQL** | 4 vCPU, 16GB RAM, 500GB SSD |
| **Redis (Pub/Sub)** | 2 vCPU, 2GB RAM |
| **Redis (Celery)** | 2 vCPU, 4GB RAM |
| **Celery Workers** | 4 vCPU, 8GB RAM (3+ workers) |

---

## Kubernetes Deployment

### **1. Namespace Setup**

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fastapi-saas
```

### **2. ConfigMap**

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fastapi-config
  namespace: fastapi-saas
data:
  PROJECT_NAME: "FastAPI-SaaS-Production"
  API_V1_STR: "/api/v1"
  ENABLE_METRICS: "true"
  LOG_LEVEL: "INFO"
```

### **3. Secrets**

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: fastapi-secrets
  namespace: fastapi-saas
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@postgres:5432/saas_db"
  SECRET_KEY: "your-secret-key-here"
  SENTRY_DSN: "https://your-sentry-dsn@sentry.io/project"
```

### **4. FastAPI Deployment**

```yaml
# fastapi-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi
  namespace: fastapi-saas
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fastapi
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      containers:
      - name: fastapi
        image: your-registry/fastapi-saas:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: fastapi-secrets
              key: DATABASE_URL
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: fastapi-secrets
              key: SECRET_KEY
        envFrom:
        - configMapRef:
            name: fastapi-config
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
```

### **5. Service**

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: fastapi-service
  namespace: fastapi-saas
spec:
  selector:
    app: fastapi
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```

### **6. Celery Worker Deployment**

```yaml
# celery-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: celery-worker
  namespace: fastapi-saas
spec:
  replicas: 3
  selector:
    matchLabels:
      app: celery-worker
  template:
    metadata:
      labels:
        app: celery-worker
    spec:
      containers:
      - name: celery-worker
        image: your-registry/fastapi-saas:latest
        command: ["celery", "-A", "app.workers.celery_app", "worker", "--loglevel=info"]
        envFrom:
        - configMapRef:
            name: fastapi-config
        - secretRef:
            name: fastapi-secrets
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
```

---

## Docker Compose Production

### **1. Production docker-compose.yml**

```yaml
version: '3.8'

services:
  fastapi:
    image: your-registry/fastapi-saas:latest
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
    ports:
      - "8000:8000"
    env_file:
      - .env.production
    depends_on:
      - postgres
      - redis-pubsub
      - redis-celery
    restart: always
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 4G

  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    env_file:
      - .env.production
    restart: always
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 16G

  redis-pubsub:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 2gb --maxmemory-policy noeviction
    volumes:
      - redis-pubsub-data:/data
    restart: always

  redis-celery:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 4gb --maxmemory-policy allkeys-lru
    volumes:
      - redis-celery-data:/data
    restart: always

  celery-worker:
    image: your-registry/fastapi-saas:latest
    command: celery -A app.workers.celery_app worker --loglevel=info --concurrency=4
    env_file:
      - .env.production
    depends_on:
      - redis-celery
      - postgres
    restart: always
    deploy:
      replicas: 3

volumes:
  postgres_data:
  redis-pubsub-data:
  redis-celery-data:
```

---

## Scaling Guidelines

### **Horizontal Scaling**

**FastAPI Instances:**
- Start with 2-3 replicas
- Add 1 replica per 1000 concurrent users
- Monitor CPU/memory usage

**Celery Workers:**
- Start with 3 workers
- Add 1 worker per 100 tasks/minute
- Monitor queue depth

### **Vertical Scaling**

**Database:**
- Upgrade when CPU > 70% sustained
- Add RAM when cache hit ratio < 95%
- Increase storage when > 80% full

**Redis:**
- Upgrade when memory > 80%
- Monitor eviction rate
- Increase maxmemory if needed

---

## Monitoring Setup

### **Prometheus**

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'fastapi'
    static_configs:
      - targets: ['fastapi:8000']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### **Grafana Dashboards**

Import dashboards for:
- FastAPI request metrics
- Celery task metrics
- PostgreSQL performance
- Redis metrics

---

## Backup Strategies

### **Database Backups**

```bash
# Daily full backup
0 2 * * * pg_dump -U postgres saas_db | gzip > /backups/saas_db_$(date +\%Y\%m\%d).sql.gz

# Hourly incremental (WAL archiving)
archive_command = 'cp %p /backups/wal/%f'
```

### **Redis Backups**

```bash
# Daily RDB snapshot
0 3 * * * docker exec redis-celery redis-cli BGSAVE
```

### **Retention Policy**

- Daily backups: Keep 30 days
- Weekly backups: Keep 12 weeks
- Monthly backups: Keep 12 months

---

## Security Checklist

- [ ] Change all default passwords
- [ ] Use strong SECRET_KEY (32+ characters)
- [ ] Enable HTTPS/TLS
- [ ] Configure CORS properly
- [ ] Set up firewall rules
- [ ] Enable database encryption at rest
- [ ] Use secrets management (Vault, AWS Secrets Manager)
- [ ] Enable audit logging
- [ ] Set up intrusion detection
- [ ] Regular security updates

---

## Performance Tuning

### **Database**

```sql
-- Connection pooling
max_connections = 200
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 64MB

-- Query optimization
random_page_cost = 1.1
effective_io_concurrency = 200
```

### **Redis**

```conf
# Pub/Sub
maxmemory 2gb
maxmemory-policy noeviction
save 900 1
save 300 10

# Celery
maxmemory 4gb
maxmemory-policy allkeys-lru
```

### **Uvicorn**

```bash
# Workers = (2 x CPU cores) + 1
uvicorn app.main:app --workers 9 --host 0.0.0.0 --port 8000
```

---

## Troubleshooting

### **High CPU Usage**

1. Check slow queries: `pg_stat_statements`
2. Review Celery task load
3. Check for infinite loops in code

### **Memory Leaks**

1. Monitor with `docker stats`
2. Check for unclosed database connections
3. Review Celery task memory usage

### **Database Connection Exhaustion**

1. Increase `max_connections`
2. Implement connection pooling (PgBouncer)
3. Review application connection handling

---

## Deployment Checklist

- [ ] Update `.env.production` with production values
- [ ] Run database migrations
- [ ] Build and push Docker images
- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Monitor for 1 hour
- [ ] Update documentation
- [ ] Notify team
