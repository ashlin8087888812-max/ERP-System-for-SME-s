# Tenant Odoo Database Upgrade Procedures

## Overview

This document outlines the procedures for upgrading tenant Odoo databases in a multi-tenant SaaS environment.

---

## Pre-Upgrade Checklist

### **1. Preparation**
- [ ] Review Odoo release notes for breaking changes
- [ ] Test upgrade on staging environment
- [ ] Notify affected tenants of maintenance window
- [ ] Verify backup retention policy
- [ ] Ensure rollback plan is ready

### **2. Environment Check**
```bash
# Check disk space
df -h

# Check database connections
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Check Celery workers
celery -A app.workers.celery_app inspect active
```

### **3. Backup Verification**
- [ ] Database backup exists and is recent
- [ ] Filestore backup exists
- [ ] Backup restoration tested within last 30 days

---

## Backup Procedures

### **1. Database Backup**

```bash
# Single tenant backup
pg_dump -U postgres -Fc company_db_1 > /backups/company_db_1_$(date +%Y%m%d_%H%M%S).dump

# All tenant databases
for db in $(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname LIKE 'company_db_%'"); do
    pg_dump -U postgres -Fc $db > /backups/${db}_$(date +%Y%m%d_%H%M%S).dump
done
```

### **2. Filestore Backup**

```bash
# Backup Odoo filestore
tar -czf /backups/odoo_filestore_$(date +%Y%m%d_%H%M%S).tar.gz /var/lib/odoo/filestore/
```

### **3. Verify Backups**

```bash
# Test database restore (to temp DB)
pg_restore -U postgres -d test_restore /backups/company_db_1_20251120.dump

# Verify filestore archive
tar -tzf /backups/odoo_filestore_20251120.tar.gz | head -20
```

---

## Upgrade Procedures

### **Single Tenant Upgrade**

```bash
#!/bin/bash
# upgrade_tenant.sh

TENANT_DB=$1
ODOO_VERSION=$2

echo "Upgrading $TENANT_DB to Odoo $ODOO_VERSION"

# 1. Backup
pg_dump -U postgres -Fc $TENANT_DB > /backups/${TENANT_DB}_pre_upgrade_$(date +%Y%m%d_%H%M%S).dump

# 2. Stop Odoo for this tenant (if using separate instances)
systemctl stop odoo-${TENANT_DB}

# 3. Run Odoo upgrade
odoo -d $TENANT_DB -u all --stop-after-init --log-level=info

# 4. Verify upgrade
psql -U postgres -d $TENANT_DB -c "SELECT name, state FROM ir_module_module WHERE state='to upgrade';"

# 5. Restart Odoo
systemctl start odoo-${TENANT_DB}

echo "Upgrade complete for $TENANT_DB"
```

**Usage:**
```bash
chmod +x upgrade_tenant.sh
./upgrade_tenant.sh company_db_1 17.0
```

---

### **Batch Tenant Upgrade**

```bash
#!/bin/bash
# batch_upgrade.sh

ODOO_VERSION=$1
BATCH_SIZE=5

# Get all tenant databases
TENANTS=$(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname LIKE 'company_db_%' ORDER BY datname;")

# Convert to array
TENANT_ARRAY=($TENANTS)
TOTAL=${#TENANT_ARRAY[@]}

echo "Upgrading $TOTAL tenants in batches of $BATCH_SIZE"

# Process in batches
for ((i=0; i<$TOTAL; i+=$BATCH_SIZE)); do
    BATCH_NUM=$((i/$BATCH_SIZE + 1))
    echo "Processing batch $BATCH_NUM..."
    
    # Upgrade batch in parallel
    for ((j=i; j<i+$BATCH_SIZE && j<$TOTAL; j++)); do
        TENANT_DB=${TENANT_ARRAY[$j]}
        ./upgrade_tenant.sh $TENANT_DB $ODOO_VERSION &
    done
    
    # Wait for batch to complete
    wait
    
    echo "Batch $BATCH_NUM complete"
    sleep 10  # Cool-down period
done

echo "All tenants upgraded"
```

**Usage:**
```bash
chmod +x batch_upgrade.sh
./batch_upgrade.sh 17.0
```

---

## Health Verification

### **1. Database Health**

```bash
# Check for upgrade errors
psql -U postgres -d company_db_1 -c "
    SELECT name, state, latest_version 
    FROM ir_module_module 
    WHERE state IN ('to upgrade', 'to install', 'to remove')
    LIMIT 20;
"

# Check database size
psql -U postgres -c "
    SELECT datname, pg_size_pretty(pg_database_size(datname)) 
    FROM pg_database 
    WHERE datname LIKE 'company_db_%'
    ORDER BY pg_database_size(datname) DESC;
"
```

### **2. Application Health**

```bash
# Check FastAPI health
curl http://localhost:8000/health

# Check Odoo health for tenant
curl http://localhost:8068/web/database/selector

# Check Celery workers
celery -A app.workers.celery_app inspect ping
```

### **3. Functional Testing**

```python
# test_post_upgrade.py
import requests

def test_tenant_login(company_id, db_name):
    """Test tenant can login after upgrade"""
    response = requests.post(
        "http://localhost:8000/api/v1/auth/login",
        json={"email": "admin@company.com", "password": "admin"}
    )
    assert response.status_code == 200
    print(f"✅ Login successful for {db_name}")

def test_tenant_operations(company_id):
    """Test basic operations"""
    # Test PO creation
    # Test GRN
    # Test inventory query
    pass

# Run for all tenants
for company_id in [1, 2, 3]:
    test_tenant_login(company_id, f"company_db_{company_id}")
```

---

## Rollback Procedures

### **1. Database Rollback**

```bash
#!/bin/bash
# rollback_tenant.sh

TENANT_DB=$1
BACKUP_FILE=$2

echo "Rolling back $TENANT_DB from $BACKUP_FILE"

# 1. Stop Odoo
systemctl stop odoo-${TENANT_DB}

# 2. Drop current database
psql -U postgres -c "DROP DATABASE IF EXISTS ${TENANT_DB};"

# 3. Restore from backup
pg_restore -U postgres -C -d postgres $BACKUP_FILE

# 4. Restart Odoo
systemctl start odoo-${TENANT_DB}

echo "Rollback complete for $TENANT_DB"
```

**Usage:**
```bash
./rollback_tenant.sh company_db_1 /backups/company_db_1_pre_upgrade_20251120.dump
```

### **2. Verify Rollback**

```bash
# Check database version
psql -U postgres -d company_db_1 -c "SELECT value FROM ir_config_parameter WHERE key='database.version';"

# Test login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@company.com","password":"admin"}'
```

---

## Troubleshooting

### **Common Issues**

**1. Module Upgrade Fails**
```bash
# Check module state
psql -U postgres -d company_db_1 -c "
    SELECT name, state, latest_version 
    FROM ir_module_module 
    WHERE state = 'to upgrade';
"

# Force module update
odoo -d company_db_1 -u module_name --stop-after-init
```

**2. Database Lock**
```bash
# Check for locks
psql -U postgres -c "
    SELECT pid, usename, application_name, state, query 
    FROM pg_stat_activity 
    WHERE datname = 'company_db_1';
"

# Kill blocking queries
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'company_db_1' AND state = 'idle in transaction';"
```

**3. Disk Space Issues**
```bash
# Check disk usage
df -h

# Clean old backups
find /backups -name "*.dump" -mtime +30 -delete

# Vacuum database
psql -U postgres -d company_db_1 -c "VACUUM FULL ANALYZE;"
```

---

## Monitoring During Upgrade

### **1. Real-time Logs**

```bash
# Odoo logs
tail -f /var/log/odoo/odoo.log | grep -i "upgrade\|error"

# PostgreSQL logs
tail -f /var/log/postgresql/postgresql-14-main.log

# FastAPI logs
docker-compose logs -f fastapi
```

### **2. Progress Tracking**

```python
# track_upgrade.py
import psycopg2
import time

def check_upgrade_progress(db_name):
    conn = psycopg2.connect(f"dbname={db_name} user=postgres")
    cur = conn.cursor()
    
    cur.execute("""
        SELECT 
            COUNT(*) FILTER (WHERE state = 'to upgrade') as to_upgrade,
            COUNT(*) FILTER (WHERE state = 'installed') as installed,
            COUNT(*) as total
        FROM ir_module_module
    """)
    
    to_upgrade, installed, total = cur.fetchone()
    progress = (installed / total) * 100
    
    print(f"{db_name}: {progress:.1f}% complete ({installed}/{total} modules)")
    
    cur.close()
    conn.close()

# Monitor all tenants
while True:
    for db in ['company_db_1', 'company_db_2', 'company_db_3']:
        check_upgrade_progress(db)
    time.sleep(30)
```

---

## Post-Upgrade Tasks

### **1. Cleanup**

```bash
# Remove old backups (keep last 7 days)
find /backups -name "*.dump" -mtime +7 -delete

# Vacuum databases
for db in $(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname LIKE 'company_db_%'"); do
    psql -U postgres -d $db -c "VACUUM ANALYZE;"
done
```

### **2. Update Documentation**

- [ ] Update tenant version in database
- [ ] Update monitoring dashboards
- [ ] Notify tenants of completion
- [ ] Document any issues encountered

### **3. Performance Verification**

```bash
# Check query performance
psql -U postgres -d company_db_1 -c "
    SELECT query, calls, total_time, mean_time 
    FROM pg_stat_statements 
    ORDER BY mean_time DESC 
    LIMIT 10;
"
```

---

## Best Practices

1. **Always test on staging first**
2. **Upgrade during low-traffic hours**
3. **Batch upgrades in groups of 5-10 tenants**
4. **Keep backups for at least 30 days**
5. **Monitor for 24 hours post-upgrade**
6. **Have rollback plan ready**
7. **Document all changes**
8. **Communicate with tenants**

---

## Emergency Contacts

- **Database Admin:** [Contact Info]
- **DevOps Lead:** [Contact Info]
- **Odoo Support:** [Contact Info]
- **On-Call Engineer:** [Contact Info]
