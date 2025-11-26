# Incident Response Runbook: Database Failure

## Scenario
PostgreSQL database is down or unreachable.

---

## Detection
- Health check endpoint returns 503
- Prometheus alert: `postgres_up == 0`
- Application logs: `psycopg2.OperationalError`

---

## Immediate Actions (5 minutes)

### 1. Verify the Issue
```bash
# Check if database is running
docker ps | grep postgres

# Check database logs
docker logs fastapi-saas-postgres-1 --tail 100

# Try to connect
psql -U postgres -h localhost -p 5432 -d saas_db
```

### 2. Check Disk Space
```bash
df -h
# If disk full, clear old logs/backups
find /var/log -name "*.log" -mtime +7 -delete
```

### 3. Restart Database (if needed)
```bash
docker-compose restart postgres

# Wait 30 seconds
sleep 30

# Verify
curl http://localhost:8000/health
```

---

## Recovery Actions (15 minutes)

### 4. Check for Corruption
```bash
# Connect to database
docker exec -it fastapi-saas-postgres-1 psql -U postgres

# Check for corruption
SELECT pg_database.datname, pg_database_size(pg_database.datname)
FROM pg_database;

# Vacuum if needed
VACUUM FULL ANALYZE;
```

### 5. Restore from Backup (if corrupted)
```bash
# Stop application
docker-compose stop fastapi celery_worker

# Drop corrupted database
docker exec -it fastapi-saas-postgres-1 psql -U postgres -c "DROP DATABASE saas_db;"

# Restore from latest backup
LATEST_BACKUP=$(ls -t /backups/*.dump | head -1)
docker exec -i fastapi-saas-postgres-1 pg_restore -U postgres -C -d postgres < $LATEST_BACKUP

# Restart services
docker-compose up -d
```

---

## Verification (5 minutes)

### 6. Verify Services
```bash
# Check health
curl http://localhost:8000/health

# Check database connections
docker exec -it fastapi-saas-postgres-1 psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Run smoke tests
pytest tests/integration/test_database.py -v
```

---

## Post-Incident

### 7. Document
- Update incident log
- Note downtime duration
- Record actions taken
- Identify root cause

### 8. Prevent Recurrence
- If disk space: Set up monitoring
- If corruption: Review backup strategy
- If connection leak: Review application code

---

## Escalation

**If issue persists after 30 minutes:**
- Escalate to Database Admin
- Contact: [DBA Contact]
- Slack: #incidents-critical

---

## Related Runbooks
- [Redis Failure](./redis_failure.md)
- [Celery Worker Failure](./celery_failure.md)
- [Complete System Restore](./disaster_recovery.md)
