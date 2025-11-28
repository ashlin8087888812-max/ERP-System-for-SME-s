# Service Level Objectives (SLOs)

## Overview

This document defines the Service Level Objectives for the FastAPI ERP/SCM backend.

---

## SLO Definitions

### **1. API Availability**

**Target:** ≥ 99.5% uptime

**Measurement:**
- Calculated over 30-day rolling window
- Excludes planned maintenance windows
- Measured via health check endpoint

**Formula:**
```
Availability = (Total Minutes - Downtime Minutes) / Total Minutes × 100
```

**Monitoring:**
```promql
# Prometheus query
(1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))) * 100
```

**Error Budget:**
- 99.5% = 216 minutes downtime/month
- 0.5% = 3.6 hours/month

---

### **2. API Latency**

**Targets:**
- P50 (median): ≤ 200ms
- P95: ≤ 500ms
- P99: ≤ 600ms

**Measurement:**
- Request duration from receipt to response
- Excludes background task processing time
- Measured at application level

**Monitoring:**
```promql
# P99 latency
histogram_quantile(0.99, rate(fastapi_request_latency_seconds_bucket[5m]))

# P95 latency
histogram_quantile(0.95, rate(fastapi_request_latency_seconds_bucket[5m]))
```

**Alerts:**
- Warning: P99 > 500ms for 5 minutes
- Critical: P99 > 600ms for 5 minutes

---

### **3. Background Task Success Rate**

**Target:** ≥ 99% success rate

**Measurement:**
- Celery task completion without errors
- Measured over 24-hour rolling window

**Formula:**
```
Success Rate = Successful Tasks / Total Tasks × 100
```

**Monitoring:**
```promql
# Success rate
(sum(rate(celery_tasks_total{status="success"}[24h])) / sum(rate(celery_tasks_total[24h]))) * 100
```

**Alerts:**
- Warning: Success rate < 99.5% for 1 hour
- Critical: Success rate < 99% for 30 minutes

---

### **4. Odoo Sync Lag**

**Target:** ≤ 30 seconds (P95)

**Measurement:**
- Time from event creation to Odoo sync completion
- Measured via audit log timestamps

**Monitoring:**
```sql
-- Query audit logs
SELECT 
    percentile_cont(0.95) WITHIN GROUP (ORDER BY sync_duration)
FROM (
    SELECT 
        EXTRACT(EPOCH FROM (odoo_synced_at - created_at)) as sync_duration
    FROM audit_logs
    WHERE created_at > NOW() - INTERVAL '1 hour'
) t;
```

**Alerts:**
- Warning: P95 > 25 seconds
- Critical: P95 > 30 seconds

---

### **5. Database Query Performance**

**Target:** P95 query time ≤ 100ms

**Measurement:**
- Database query execution time
- Measured via pg_stat_statements

**Monitoring:**
```sql
SELECT 
    query,
    mean_exec_time,
    max_exec_time,
    calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;
```

---

### **6. Error Rate**

**Target:** < 0.1% of requests

**Measurement:**
- HTTP 5xx responses
- Application exceptions

**Monitoring:**
```promql
# Error rate
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

**Alerts:**
- Warning: Error rate > 0.05% for 5 minutes
- Critical: Error rate > 0.1% for 5 minutes

---

### **7. Cache Hit Rate**

**Target:** ≥ 80%

**Measurement:**
- Redis cache hits vs misses
- Inventory snapshot cache

**Monitoring:**
```python
# Track in code
cache_hits = redis.get("cache:hits")
cache_misses = redis.get("cache:misses")
hit_rate = cache_hits / (cache_hits + cache_misses) * 100
```

---

## SLO Dashboard

### **Grafana Panels**

1. **Availability** (Single Stat)
   - Current: 99.8%
   - Target: 99.5%
   - Status: ✅

2. **Latency** (Graph)
   - P50, P95, P99 over time
   - Target lines

3. **Error Rate** (Graph)
   - 5xx errors over time
   - Target threshold

4. **Background Tasks** (Single Stat)
   - Success rate: 99.5%
   - Target: 99%
   - Status: ✅

5. **Sync Lag** (Histogram)
   - Distribution of sync times
   - P95 marker

---

## Incident Response

### **SLO Violation Response**

**When SLO is breached:**
1. Auto-alert via PagerDuty/Slack
2. Incident commander assigned
3. Follow runbook (see `/docs/runbooks/`)
4. Post-incident review within 48 hours

**Severity Levels:**
- **SEV1:** Multiple SLOs breached, customer impact
- **SEV2:** Single SLO breached, degraded service
- **SEV3:** SLO at risk, no customer impact yet

---

## Review Cadence

- **Weekly:** Review SLO metrics in team meeting
- **Monthly:** SLO report to stakeholders
- **Quarterly:** SLO target review and adjustment

---

## Historical SLO Performance

| Month | Availability | P99 Latency | Task Success | Sync Lag |
|-------|-------------|-------------|--------------|----------|
| Nov 2024 | 99.8% ✅ | 450ms ✅ | 99.6% ✅ | 22s ✅ |
| Oct 2024 | 99.7% ✅ | 480ms ✅ | 99.4% ✅ | 28s ✅ |
| Sep 2024 | 99.6% ✅ | 520ms ⚠️ | 99.2% ✅ | 25s ✅ |

---

## Error Budget Policy

**When error budget is exhausted:**
1. Freeze feature releases
2. Focus on reliability improvements
3. Conduct blameless post-mortem
4. Update runbooks

**Error budget reset:** Monthly
