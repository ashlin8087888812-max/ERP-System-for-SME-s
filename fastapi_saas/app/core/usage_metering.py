"""
Usage Metering for Billing.

Tracks usage metrics for billing purposes.
"""
from datetime import datetime
from typing import Dict, List
from prometheus_client import Counter, Histogram
from app.redis_client.client import get_redis_client


# Prometheus metrics for billing
BILLABLE_API_CALLS = Counter(
    'billable_api_calls_total',
    'Total billable API calls',
    ['company_id', 'endpoint']
)

BILLABLE_EVENTS = Counter(
    'billable_events_total',
    'Total billable events processed',
    ['company_id', 'event_type']
)

BILLABLE_STORAGE = Histogram(
    'billable_storage_bytes',
    'Storage usage in bytes',
    ['company_id']
)

BILLABLE_BACKGROUND_TASKS = Counter(
    'billable_background_tasks_total',
    'Total billable background tasks',
    ['company_id', 'task_type']
)


class UsageMetering:
    """Track usage for billing purposes"""
    
    @staticmethod
    async def track_api_call(company_id: int, endpoint: str):
        """Track API call for billing"""
        # Prometheus metric
        BILLABLE_API_CALLS.labels(
            company_id=str(company_id),
            endpoint=endpoint
        ).inc()
        
        # Redis counter (for real-time billing)
        redis = await get_redis_client()
        key = f"billing:{company_id}:api_calls:{datetime.now().strftime('%Y%m')}"
        await redis.incr(key)
        await redis.expire(key, 86400 * 90)  # Keep 90 days
    
    @staticmethod
    async def track_event(company_id: int, event_type: str):
        """Track event processing for billing"""
        BILLABLE_EVENTS.labels(
            company_id=str(company_id),
            event_type=event_type
        ).inc()
        
        redis = await get_redis_client()
        key = f"billing:{company_id}:events:{datetime.now().strftime('%Y%m')}"
        await redis.incr(key)
        await redis.expire(key, 86400 * 90)
    
    @staticmethod
    async def track_background_task(company_id: int, task_type: str):
        """Track background task for billing"""
        BILLABLE_BACKGROUND_TASKS.labels(
            company_id=str(company_id),
            task_type=task_type
        ).inc()
        
        redis = await get_redis_client()
        key = f"billing:{company_id}:tasks:{datetime.now().strftime('%Y%m')}"
        await redis.incr(key)
        await redis.expire(key, 86400 * 90)
    
    @staticmethod
    async def track_storage(company_id: int, bytes_used: int):
        """Track storage usage for billing"""
        BILLABLE_STORAGE.labels(company_id=str(company_id)).observe(bytes_used)
        
        redis = await get_redis_client()
        key = f"billing:{company_id}:storage"
        await redis.set(key, bytes_used)
    
    @staticmethod
    async def get_monthly_usage(company_id: int, month: str = None) -> Dict:
        """
        Get usage for a specific month.
        
        Args:
            company_id: Company ID
            month: Month in YYYYMM format (default: current month)
        
        Returns:
            Dict with usage metrics
        """
        if not month:
            month = datetime.now().strftime('%Y%m')
        
        redis = await get_redis_client()
        
        # Get all usage metrics
        api_calls = await redis.get(f"billing:{company_id}:api_calls:{month}")
        events = await redis.get(f"billing:{company_id}:events:{month}")
        tasks = await redis.get(f"billing:{company_id}:tasks:{month}")
        storage = await redis.get(f"billing:{company_id}:storage")
        
        return {
            "company_id": company_id,
            "month": month,
            "api_calls": int(api_calls) if api_calls else 0,
            "events_processed": int(events) if events else 0,
            "background_tasks": int(tasks) if tasks else 0,
            "storage_bytes": int(storage) if storage else 0,
            "storage_gb": round(int(storage) / (1024**3), 2) if storage else 0
        }
    
    @staticmethod
    async def calculate_bill(company_id: int, month: str = None) -> Dict:
        """
        Calculate bill based on usage.
        
        Pricing (example):
        - API calls: $0.001 per call
        - Events: $0.01 per event
        - Background tasks: $0.005 per task
        - Storage: $0.10 per GB/month
        """
        usage = await UsageMetering.get_monthly_usage(company_id, month)
        
        # Pricing
        api_call_price = 0.001
        event_price = 0.01
        task_price = 0.005
        storage_price_per_gb = 0.10
        
        # Calculate costs
        api_cost = usage['api_calls'] * api_call_price
        event_cost = usage['events_processed'] * event_price
        task_cost = usage['background_tasks'] * task_price
        storage_cost = usage['storage_gb'] * storage_price_per_gb
        
        total = api_cost + event_cost + task_cost + storage_cost
        
        return {
            **usage,
            "costs": {
                "api_calls": round(api_cost, 2),
                "events": round(event_cost, 2),
                "background_tasks": round(task_cost, 2),
                "storage": round(storage_cost, 2),
                "total": round(total, 2)
            }
        }


# Middleware to track API calls
"""
@app.middleware("http")
async def usage_tracking_middleware(request: Request, call_next):
    response = await call_next(request)
    
    # Track if authenticated and successful
    if hasattr(request.state, 'tenant') and response.status_code < 400:
        await UsageMetering.track_api_call(
            request.state.tenant['company_id'],
            request.url.path
        )
    
    return response
"""
