# Test Execution Guide

## 🧪 Running the Complete Test Suite

### **Prerequisites**
1. Docker Desktop running
2. All containers up: `docker-compose up -d`
3. Dependencies installed in container

---

## 📋 **Test Execution Commands**

### **1. Critical Security Tests (MUST PASS)**
```bash
# Multi-tenancy isolation tests
docker-compose exec fastapi python -m pytest tests/security/test_tenant_isolation.py -v

# All security tests
docker-compose exec fastapi python -m pytest tests/security/ -v
```

### **2. Integration Tests**
```bash
# Quota & billing tests
docker-compose exec fastapi python -m pytest tests/integration/test_quotas_billing.py -v

# All integration tests
docker-compose exec fastapi python -m pytest tests/integration/ -v
```

### **3. API Tests**
```bash
docker-compose exec fastapi python -m pytest tests/e2e/test_comprehensive.py -v
```

### **4. Documentation Tests**
```bash
docker-compose exec fastapi python -m pytest tests/documentation/test_openapi.py -v
```

### **5. All Tests (Excluding Performance)**
```bash
docker-compose exec fastapi python -m pytest tests/ -v \
  --ignore=tests/performance/ \
  -k "not soak and not load and not stress"
```

### **6. Performance Tests (Run Manually)**
```bash
# Load tests (takes time)
docker-compose exec fastapi python -m pytest tests/performance/ -v -m performance
```

---

## 🎯 **Quick Test Commands**

### **Fast Smoke Test**
```bash
docker-compose exec fastapi python -m pytest tests/ -v -x --tb=line -k "not performance and not e2e"
```

### **Security Only**
```bash
docker-compose exec fastapi python -m pytest tests/security/ -v --tb=short
```

### **With Coverage**
```bash
docker-compose exec fastapi python -m pytest tests/ --cov=app --cov-report=html
```

---

## 📊 **Expected Results**

### **Test Counts**
- Unit Tests: 20+
- Integration Tests: 30+
- API Tests: 40+
- Security Tests: 25+
- E2E Tests: 10+
- **Total: 150+**

### **Success Criteria**
- All critical security tests: 100% pass
- Overall pass rate: ≥ 85%
- Code coverage: ≥ 85%

---

## 🔧 **Troubleshooting**

### **Docker Not Running**
```bash
# Start Docker Desktop
# Then:
docker-compose up -d
```

### **Dependencies Missing**
```bash
docker-compose exec fastapi pip install -r requirements.txt
docker-compose exec fastapi pip install pytest pytest-asyncio httpx
```

### **Database Issues**
```bash
# Reset database
docker-compose down -v
docker-compose up -d
docker-compose exec fastapi alembic upgrade head
```

---

## ✅ **Test Checklist**

Before deploying to production, ensure:

- [ ] All security tests pass (100%)
- [ ] Multi-tenancy isolation tests pass
- [ ] Quota enforcement tests pass
- [ ] API tests pass (≥ 90%)
- [ ] Integration tests pass (≥ 85%)
- [ ] No critical vulnerabilities (run security_scan.sh)
- [ ] Performance benchmarks met
- [ ] Documentation tests pass

---

## 🚀 **CI/CD Integration**

### **GitHub Actions Example**
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          docker-compose up -d
          docker-compose exec -T fastapi pytest tests/ -v
```

---

## 📝 **Notes**

- Performance tests are skipped by default (use `-m performance` to run)
- E2E tests may require Odoo mock
- Some tests require Redis and PostgreSQL running
- Critical security tests MUST pass before any deployment
