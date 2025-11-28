"""
Inventory snapshot caching with Redis.

Provides fast inventory queries with TTL-based caching
and invalidation on stock mutations.
"""
import json
from typing import Optional, Dict, Any
from app.redis_client.client import get_redis_client
from app.odoo_client.client import OdooClient


async def get_inventory_snapshot(company_id: int, db_name: str, odoo_host: str) -> Dict[str, Any]:
    """
    Get cached inventory snapshot or rebuild from Odoo.
    
    Returns inventory data with structure:
    {
        "sku_totals": {"SKU123": 100, "SKU456": 50},
        "warehouses": {
            "warehouse_1": {"SKU123": 60, "SKU456": 30},
            "warehouse_2": {"SKU123": 40, "SKU456": 20}
        }
    }
    
    Args:
        company_id: Tenant company ID
        db_name: Odoo database name
        odoo_host: Odoo host URL
    
    Returns:
        Inventory snapshot dictionary
    """
    redis = await get_redis_client()
    cache_key = f"inventory_snapshot:{company_id}"
    
    # Try to get from cache
    cached_data = await redis.get(cache_key)
    if cached_data:
        return json.loads(cached_data)
    
    # Cache miss - rebuild from Odoo
    snapshot = await _build_snapshot_from_odoo(db_name, odoo_host)
    
    # Store in cache with 60 second TTL
    await redis.setex(cache_key, 60, json.dumps(snapshot))
    
    return snapshot


async def _build_snapshot_from_odoo(db_name: str, odoo_host: str) -> Dict[str, Any]:
    """
    Build inventory snapshot by querying Odoo stock.quant.
    
    This is a fallback when cache is empty.
    Should be executed in a thread pool for sync Odoo RPC.
    """
    # TODO: Implement actual Odoo RPC call
    # For now, return empty snapshot
    # In production, this would call:
    # odoo_client = OdooClient(odoo_host, db_name, uid, password)
    # quants = odoo_client.execute_kw('stock.quant', 'search_read', ...)
    
    return {
        "sku_totals": {},
        "warehouses": {}
    }


async def invalidate_inventory(company_id: int) -> None:
    """
    Invalidate inventory cache for a company.
    
    Call this after:
    - GRN completion
    - Internal transfer completion
    - Production completion
    - Any stock mutation
    
    Args:
        company_id: Tenant company ID
    """
    redis = await get_redis_client()
    cache_key = f"inventory_snapshot:{company_id}"
    await redis.delete(cache_key)


async def update_inventory_partial(
    company_id: int,
    sku: str,
    warehouse_id: str,
    quantity_delta: int
) -> None:
    """
    Update inventory cache partially without full rebuild.
    
    This is an optimization for small changes.
    If cache doesn't exist, this is a no-op (will rebuild on next read).
    
    Args:
        company_id: Tenant company ID
        sku: Product SKU
        warehouse_id: Warehouse identifier
        quantity_delta: Change in quantity (positive or negative)
    """
    redis = await get_redis_client()
    cache_key = f"inventory_snapshot:{company_id}"
    
    cached_data = await redis.get(cache_key)
    if not cached_data:
        # Cache doesn't exist, skip update
        return
    
    snapshot = json.loads(cached_data)
    
    # Update SKU total
    current_total = snapshot["sku_totals"].get(sku, 0)
    snapshot["sku_totals"][sku] = current_total + quantity_delta
    
    # Update warehouse quantity
    if warehouse_id not in snapshot["warehouses"]:
        snapshot["warehouses"][warehouse_id] = {}
    
    current_warehouse_qty = snapshot["warehouses"][warehouse_id].get(sku, 0)
    snapshot["warehouses"][warehouse_id][sku] = current_warehouse_qty + quantity_delta
    
    # Update cache with same TTL
    ttl = await redis.ttl(cache_key)
    if ttl > 0:
        await redis.setex(cache_key, ttl, json.dumps(snapshot))
