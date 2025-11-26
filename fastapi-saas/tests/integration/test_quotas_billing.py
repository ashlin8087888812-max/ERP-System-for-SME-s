"""
Tenant Quota & Billing Tests

Tests quota enforcement and usage metering.
"""
import pytest
import uuid
from app.core.quotas import TenantQuotas
from app.core.usage_metering import UsageMetering


@pytest.mark.asyncio
class TestQuotaEnforcement:
    """Test per-tenant quota enforcement"""
    
    @pytest.mark.asyncio
    async def test_api_call_quota_enforcement(self, test_company):
        """Test API call quota is enforced"""
        from fastapi import HTTPException
        
        company_id = test_company.id
        
        # Set low quota for testing
        await TenantQuotas.set_quota(company_id, "max_api_calls_per_minute", 5)
        
        # Make 5 requests (should succeed)
        for i in range(5):
            result = await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
            assert result is True
        
        # 6th request should fail with 429
        with pytest.raises(HTTPException) as exc:
            await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
        
        assert exc.value.status_code == 429
        assert "quota exceeded" in str(exc.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_event_quota_enforcement(self, test_company):
        """Test event processing quota"""
        from fastapi import HTTPException
        
        company_id = test_company.id
        
        # Set quota
        await TenantQuotas.set_quota(company_id, "max_events_per_minute", 10)
        
        # Process 10 events
        for i in range(10):
            await TenantQuotas.check_quota(company_id, "max_events_per_minute")
        
        # 11th should fail with 429
        with pytest.raises(HTTPException) as exc:
            await TenantQuotas.check_quota(company_id, "max_events_per_minute")
            
        assert exc.value.status_code == 429
    
    @pytest.mark.asyncio
    async def test_quota_reset_after_window(self, test_company):
        """Test quota resets after time window"""
        import asyncio
        
        company_id = test_company.id
        
        # Set quota
        await TenantQuotas.set_quota(company_id, "max_api_calls_per_minute", 2)
        
        # Use quota
        await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
        await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
        
        # Should be exhausted
        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc:
            await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
            
        assert exc.value.status_code == 429
        
        # Wait for reset (in real test, mock time)
        await asyncio.sleep(61)
        
        # Should work again
        result = await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
        assert result is True
    
    @pytest.mark.asyncio
    async def test_quota_usage_reporting(self, test_company):
        """Test quota usage can be queried"""
        company_id = test_company.id
        
        # Set quota
        await TenantQuotas.set_quota(company_id, "max_api_calls_per_minute", 100)
        
        # Use some quota
        for i in range(25):
            await TenantQuotas.check_quota(company_id, "max_api_calls_per_minute")
        
        # Check usage
        usage = await TenantQuotas.get_usage(company_id, "max_api_calls_per_minute")
        
        assert usage["limit"] == 100
        assert usage["current"] == 25
        assert usage["remaining"] == 75
        assert usage["percentage"] == 25.0


@pytest.mark.asyncio
class TestUsageMetering:
    """Test usage metering for billing"""
    
    @pytest.mark.asyncio
    async def test_api_call_metering(self, test_company):
        """Test API calls are metered"""
        company_id = test_company.id
        
        # Track API calls
        await UsageMetering.track_api_call(company_id, "/api/v1/users")
        await UsageMetering.track_api_call(company_id, "/api/v1/users")
        await UsageMetering.track_api_call(company_id, "/api/v1/purchase-orders")
        
        # Get usage
        usage = await UsageMetering.get_monthly_usage(company_id)
        
        assert usage["api_calls"] >= 3
    
    @pytest.mark.asyncio
    async def test_event_metering(self, test_company):
        """Test events are metered"""
        company_id = test_company.id
        
        # Track events
        await UsageMetering.track_event(company_id, "po.create")
        await UsageMetering.track_event(company_id, "grn.create")
        
        # Get usage
        usage = await UsageMetering.get_monthly_usage(company_id)
        
        assert usage["events_processed"] >= 2
    
    @pytest.mark.asyncio
    async def test_billing_calculation(self, test_company):
        """Test billing calculation from usage"""
        company_id = test_company.id
        
        # Simulate usage
        for i in range(100):
            await UsageMetering.track_api_call(company_id, "/api/v1/test")
        
        for i in range(10):
            await UsageMetering.track_event(company_id, "test.event")
        
        # Calculate bill
        bill = await UsageMetering.calculate_bill(company_id)
        
        assert "costs" in bill
        assert "total" in bill["costs"]
        assert bill["costs"]["total"] > 0
    
    @pytest.mark.asyncio
    async def test_monthly_usage_reset(self, test_company):
        """Test usage resets monthly"""
        from datetime import datetime, timedelta
        
        company_id = test_company.id
        
        # Track usage for current month
        current_month = datetime.now().strftime('%Y%m')
        await UsageMetering.track_api_call(company_id, "/api/v1/test")
        
        # Get current month usage
        usage_current = await UsageMetering.get_monthly_usage(company_id, current_month)
        assert usage_current["api_calls"] >= 1
        
        # Get previous month usage (should be 0)
        # Calculate previous month
        today = datetime.now()
        first = today.replace(day=1)
        last_month = first - timedelta(days=1)
        previous_month = last_month.strftime('%Y%m')
        
        usage_previous = await UsageMetering.get_monthly_usage(company_id, previous_month)
        assert usage_previous["api_calls"] == 0
