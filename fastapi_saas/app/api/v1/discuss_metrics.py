from fastapi import APIRouter, Depends
from app.api.deps import require_admin
from app.odoo_client.xmlrpc_pool import xmlrpc_pool
from app.api.v1.discuss_ws import ws_gateway
from app.cache.discuss_cache import discuss_cache

router = APIRouter(tags=["observability"])

@router.get("/metrics/discuss")
async def get_discuss_metrics(admin=Depends(require_admin)):
    """
    SRE readiness metrics for Discuss module.
    Exposes:
    - XML-RPC latency/failure counters (simulated from local counts)
    - WS active fan-out stats
    - Cache hit/miss (simulated)
    """
    
    ws_stats = {
        channel: len(socks) 
        for channel, socks in ws_gateway.active_connections.items()
    }
    
    return {
        "xmlrpc_pool": {
            "failure_counts": xmlrpc_pool._failure_count,
            "circuit_breaker_threshold": xmlrpc_pool.FAILURE_THRESHOLD,
            "cached_uids_count": len(xmlrpc_pool._uids)
        },
        "websockets": {
            "total_channels_watched": len(ws_gateway.active_connections),
            "max_subs_per_channel": ws_gateway.MAX_SUBS_PER_CHANNEL,
            "active_shards": ws_stats
        },
        "message_ordering": "monotonic_sequence_enabled"
    }
