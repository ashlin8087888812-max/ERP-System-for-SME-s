#!/bin/bash
# Security Vulnerability Scanner
# Runs multiple security checks before deployment

set -e

echo "🔒 Running Security Vulnerability Scans..."
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED=0

# 1. Python Dependency Scan
echo ""
echo "📦 Scanning Python dependencies..."
if command -v safety &> /dev/null; then
    safety check --json > safety_report.json || FAILED=$((FAILED+1))
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ No known vulnerabilities in dependencies${NC}"
    else
        echo -e "${RED}✗ Vulnerabilities found in dependencies${NC}"
        cat safety_report.json
    fi
else
    echo -e "${YELLOW}⚠ safety not installed. Run: pip install safety${NC}"
fi

# 2. Docker Image Scan
echo ""
echo "🐳 Scanning Docker images..."
if command -v trivy &> /dev/null; then
    trivy image --severity HIGH,CRITICAL fastapi-saas:latest || FAILED=$((FAILED+1))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ No critical vulnerabilities in Docker image${NC}"
    else
        echo -e "${RED}✗ Vulnerabilities found in Docker image${NC}"
    fi
else
    echo -e "${YELLOW}⚠ trivy not installed. Run: brew install trivy${NC}"
fi

# 3. Security Headers Check
echo ""
echo "🌐 Checking security headers..."
if command -v curl &> /dev/null; then
    HEADERS=$(curl -sI http://localhost:8000/health/live)
    
    # Check for required headers
    if echo "$HEADERS" | grep -q "X-Content-Type-Options: nosniff"; then
        echo -e "${GREEN}✓ X-Content-Type-Options present${NC}"
    else
        echo -e "${RED}✗ X-Content-Type-Options missing${NC}"
        FAILED=$((FAILED+1))
    fi
    
    if echo "$HEADERS" | grep -q "X-Frame-Options: DENY"; then
        echo -e "${GREEN}✓ X-Frame-Options present${NC}"
    else
        echo -e "${RED}✗ X-Frame-Options missing${NC}"
        FAILED=$((FAILED+1))
    fi
    
    if echo "$HEADERS" | grep -q "Content-Security-Policy"; then
        echo -e "${GREEN}✓ Content-Security-Policy present${NC}"
    else
        echo -e "${RED}✗ Content-Security-Policy missing${NC}"
        FAILED=$((FAILED+1))
    fi
else
    echo -e "${YELLOW}⚠ curl not available${NC}"
fi

# 4. Secrets Scan
echo ""
echo "🔑 Scanning for exposed secrets..."
if command -v gitleaks &> /dev/null; then
    gitleaks detect --no-git || FAILED=$((FAILED+1))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ No secrets found in code${NC}"
    else
        echo -e "${RED}✗ Potential secrets found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ gitleaks not installed. Run: brew install gitleaks${NC}"
fi

# 5. SQL Injection Test
echo ""
echo "💉 Testing SQL injection protection..."
RESPONSE=$(curl -s "http://localhost:8000/api/v1/scm/test?id=1'%20OR%20'1'='1")
if echo "$RESPONSE" | grep -q "error\|404\|422"; then
    echo -e "${GREEN}✓ SQL injection protection working${NC}"
else
    echo -e "${RED}✗ Potential SQL injection vulnerability${NC}"
    FAILED=$((FAILED+1))
fi

# 6. Rate Limiting Test
echo ""
echo "⏱️  Testing rate limiting..."
for i in {1..70}; do
    curl -s http://localhost:8000/health/live > /dev/null
done
RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8000/health/live -o /dev/null)
if [ "$RESPONSE" == "429" ]; then
    echo -e "${GREEN}✓ Rate limiting working${NC}"
else
    echo -e "${YELLOW}⚠ Rate limiting may not be configured${NC}"
fi

# 7. HTTPS Check (for production)
echo ""
echo "🔐 Checking HTTPS configuration..."
if [ "$ENVIRONMENT" == "production" ]; then
    if curl -sI https://your-domain.com | grep -q "Strict-Transport-Security"; then
        echo -e "${GREEN}✓ HSTS header present${NC}"
    else
        echo -e "${RED}✗ HSTS header missing in production${NC}"
        FAILED=$((FAILED+1))
    fi
else
    echo -e "${YELLOW}⚠ Skipping HTTPS check (not production)${NC}"
fi

# Summary
echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All security checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED security check(s) failed${NC}"
    echo "Please fix the issues before deploying to production."
    exit 1
fi
