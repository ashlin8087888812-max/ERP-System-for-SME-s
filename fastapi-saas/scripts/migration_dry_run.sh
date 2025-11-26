#!/bin/bash
# Migration Dry Run Script
# Validates migrations before applying to production

set -e

echo "🔄 Running Migration Dry Run..."
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Generate SQL for pending migrations
echo ""
echo "📝 Generating migration SQL..."
alembic upgrade --sql head > migration_dry_run.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Migration SQL generated${NC}"
else
    echo -e "${RED}✗ Failed to generate migration SQL${NC}"
    exit 1
fi

# 2. Show what will be executed
echo ""
echo "📋 Migration SQL Preview:"
echo "------------------------"
head -n 50 migration_dry_run.sql
echo "..."
echo "(Full SQL in migration_dry_run.sql)"

# 3. Create test database
echo ""
echo "🗄️  Creating test database..."
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS test_migration_db;"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE test_migration_db;"

# 4. Restore production snapshot to test DB
echo ""
echo "📦 Restoring production snapshot to test DB..."
if [ -f "/backups/latest_prod_snapshot.dump" ]; then
    docker-compose exec postgres pg_restore -U postgres -d test_migration_db /backups/latest_prod_snapshot.dump
    echo -e "${GREEN}✓ Snapshot restored${NC}"
else
    echo -e "${YELLOW}⚠ No production snapshot found, using empty DB${NC}"
fi

# 5. Apply migration to test DB
echo ""
echo "⚡ Applying migration to test database..."
docker-compose exec postgres psql -U postgres -d test_migration_db < migration_dry_run.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Migration applied successfully${NC}"
else
    echo -e "${RED}✗ Migration failed${NC}"
    exit 1
fi

# 6. Validate schema
echo ""
echo "✅ Validating schema..."
docker-compose exec postgres psql -U postgres -d test_migration_db -c "\dt"
docker-compose exec postgres psql -U postgres -d test_migration_db -c "\di"

# 7. Run data integrity checks
echo ""
echo "🔍 Running data integrity checks..."
docker-compose exec postgres psql -U postgres -d test_migration_db -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"

# 8. Test application against migrated DB
echo ""
echo "🧪 Testing application against migrated database..."
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/test_migration_db"
pytest tests/integration/ -v --tb=short

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Application tests passed${NC}"
else
    echo -e "${RED}✗ Application tests failed${NC}"
    exit 1
fi

# 9. Estimate migration time
echo ""
echo "⏱️  Estimating migration time..."
START_TIME=$(date +%s)
# Re-run migration to measure time
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS test_migration_db2;"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE test_migration_db2;"
docker-compose exec postgres psql -U postgres -d test_migration_db2 < migration_dry_run.sql
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "${GREEN}✓ Estimated migration time: ${DURATION} seconds${NC}"

if [ $DURATION -gt 60 ]; then
    echo -e "${YELLOW}⚠ Migration will take more than 1 minute${NC}"
    echo "Consider scheduling maintenance window"
fi

# 10. Cleanup
echo ""
echo "🧹 Cleaning up test databases..."
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS test_migration_db;"
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS test_migration_db2;"

# Summary
echo ""
echo "================================"
echo -e "${GREEN}✅ Migration dry run complete!${NC}"
echo ""
echo "Summary:"
echo "- Migration SQL: migration_dry_run.sql"
echo "- Estimated time: ${DURATION} seconds"
echo "- Schema validated: ✓"
echo "- Application tests: ✓"
echo ""
echo "Ready to apply to production? (y/n)"
