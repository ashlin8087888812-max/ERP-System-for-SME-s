# Incident Response Runbook: Stuck Celery Workers

## Scenario
Celery workers are stuck, not processing tasks, or queue is backing up.

---

## Detection
- Flower shows workers idle but queue growing
- Prometheus alert: `celery_queue_depth > 100`
- Customer reports: "Orders not syncing to Odoo"

---

## Immediate Actions (5 minutes)

### 1. Check Worker Status
```bash
# Check Celery workers
docker-compose exec celery_worker celery -A app.workers.celery_app inspect active

# Check queue depth
docker-compose exec celery_worker celery -A app.workers.celery_app inspect stats

# Check Flower dashboard
open http://localhost:5555
```

### 2. Identify Stuck Tasks
```bash
# List active tasks
docker-compose exec celery_worker celery -A app.workers.celery_app inspect active

# Check for long-running tasks
docker-compose exec celery_worker celery -A app.workers.celery_app inspect active | grep -A 5 "time_start"
```

---

## Recovery Actions (15 minutes)

### 3. Restart Workers (Graceful)
```bash
# Graceful restart (waits for tasks to complete)
docker-compose exec celery_worker celery -A app.workers.celery_app control shutdown

# Wait 30 seconds
sleep 30

# Restart
docker-compose restart celery_worker

# Verify
docker-compose exec celery_worker celery -A app.workers.celery_app inspect ping
```

### 4. Purge Stuck Tasks (if needed)
```bash
# WARNING: This deletes tasks!
# Only use if tasks are truly stuck

# Purge specific queue
docker-compose exec celery_worker celery -A app.workers.celery_app purge -Q celery

# Or purge all
docker-compose exec celery_worker celery -A app.workers.celery_app purge
```

### 5. Revoke Stuck Tasks
```bash
# Get task ID from Flower or logs
TASK_ID="abc-123-def-456"

# Revoke task
docker-compose exec celery_worker celery -A app.workers.celery_app control revoke $TASK_ID --terminate
```

---

## Advanced Recovery

### 6. Scale Workers
```bash
# Add more workers temporarily
docker-compose up -d --scale celery_worker=3

# Verify
docker-compose ps | grep celery_worker
```

### 7. Check Odoo Connectivity
```bash
# Test Odoo connection
docker-compose exec celery_worker python -c "
from app.odoo_client.client import OdooClient
client = OdooClient()
print(client.authenticate('company_db_1'))
"
```

### 8. Reprocess Failed Events
```python
# In Python shell
from app.db.idempotency import get_event_status, mark_processed
from app.db.base import SessionLocal

db = SessionLocal()

# Find failed events
failed_events = db.query(EventProcessed).filter(
    EventProcessed.status == 'failed',
    EventProcessed.updated_at > datetime.now() - timedelta(hours=1)
).all()

# Reset to pending
for event in failed_events:
    event.status = 'pending'
    db.commit()

# Re-enqueue tasks
for event in failed_events:
    # Re-enqueue based on event_type
    if event.event_type == 'po.create':
        persist_po_to_odoo.delay(...)
```

---

## Verification (5 minutes)

### 9. Monitor Queue
```bash
# Watch queue depth decrease
watch -n 5 'docker-compose exec celery_worker celery -A app.workers.celery_app inspect stats | grep "total"'

# Check Flower
open http://localhost:5555
```

### 10. Verify Task Processing
```bash
# Check recent successful tasks
docker-compose exec celery_worker celery -A app.workers.celery_app events

# Check audit logs
psql -U postgres -d saas_db -c "
SELECT * FROM audit_logs 
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 20;
"
```

---

## Post-Incident

### 11. Root Cause Analysis
- Check worker logs for errors
- Review Odoo response times
- Check database connection pool
- Review task timeout settings

### 12. Prevent Recurrence
- Adjust worker concurrency
- Add task timeouts
- Implement circuit breaker for Odoo
- Add queue depth monitoring

---

## Escalation

**If queue not clearing after 30 minutes:**
- Escalate to Backend Team Lead
- Contact: [Team Lead]
- Slack: #incidents-critical

---

## Related Runbooks
- [Odoo Connection Failure](./odoo_failure.md)
- [Redis Failure](./redis_failure.md)
- [High Queue Depth](./high_queue_depth.md)
