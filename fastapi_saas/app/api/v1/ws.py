from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from app.core import jwt as core_jwt
from app.redis_client.client import get_redis_client
from app.config import settings
import asyncio
import json
import logging
from datetime import datetime

router = APIRouter()
logger = logging.getLogger(__name__)


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
    branch_id: int = Query(None)
):
    """
    WebSocket endpoint with Redis Pub/Sub for scaling.
    
    Features:
    - Redis Pub/Sub for message distribution across instances
    - Presence tracking (connection count)
    - Heartbeat/ping mechanism
    - Graceful disconnect handling
    """
    # Authenticate
    payload = core_jwt.decode_token(token)
    if not payload:
        await websocket.close(code=1008)  # Policy violation
        return
    
    company_id = payload.get("company_id")
    user_id = payload.get("sub")
    
    if not company_id or not user_id:
        await websocket.close(code=1008)
        return
    
    await websocket.accept()
    
    # Get Redis client
    redis = await get_redis_client()
    pubsub = redis.pubsub()
    
    # Subscribe to company-specific channels
    channels = [f"live:company:{company_id}"]
    if branch_id:
        channels.append(f"live:company:{company_id}:branch:{branch_id}")
    
    await pubsub.subscribe(*channels)
    
    # Generate unique connection ID
    import uuid
    conn_id = str(uuid.uuid4())
    
    # Track presence - increment connection count
    conn_key = f"ws_conn:{conn_id}"
    count_key = f"ws_connections:company:{company_id}:count"
    
    await redis.setex(conn_key, 300, user_id)  # 5 min TTL
    await redis.incr(count_key)
    
    logger.info(f"User {user_id} connected to company {company_id} (conn: {conn_id})")
    
    # Create task for reading from Redis Pub/Sub
    async def redis_reader():
        """Read messages from Redis Pub/Sub and send to WebSocket"""
        try:
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    data = message['data']
                    if isinstance(data, bytes):
                        data = data.decode('utf-8')
                    await websocket.send_text(data)
        except Exception as e:
            logger.error(f"Redis reader error: {e}")
    
    # Create task for handling client messages (ping/pong)
    async def client_reader():
        """Read messages from WebSocket client"""
        try:
            while True:
                data = await websocket.receive_text()
                
                # Handle ping/pong
                if data == "ping":
                    await websocket.send_text("pong")
                    # Refresh connection TTL
                    await redis.expire(conn_key, 300)
                else:
                    # Handle other client messages if needed
                    logger.debug(f"Received from client: {data}")
        except WebSocketDisconnect:
            logger.info(f"Client {user_id} disconnected")
        except Exception as e:
            logger.error(f"Client reader error: {e}")
    
    # Run both tasks concurrently
    redis_task = asyncio.create_task(redis_reader())
    client_task = asyncio.create_task(client_reader())
    
    try:
        # Wait for either task to complete (usually on disconnect)
        done, pending = await asyncio.wait(
            [redis_task, client_task],
            return_when=asyncio.FIRST_COMPLETED
        )
        
        # Cancel remaining tasks
        for task in pending:
            task.cancel()
            
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        
    finally:
        # Cleanup: unsubscribe, decrement count, delete connection key
        await pubsub.unsubscribe(*channels)
        await redis.decr(count_key)
        await redis.delete(conn_key)
        
        logger.info(f"User {user_id} disconnected from company {company_id}")
        
        try:
            await websocket.close()
        except:
            pass


async def publish_to_company(company_id: int, message: dict):
    """
    Helper function to publish message to company channel.
    
    Usage in Celery tasks or endpoints:
        await publish_to_company(company_id, {
            "type": "po.created",
            "data": {"po_id": 123}
        })
    """
    redis = await get_redis_client()
    channel = f"live:company:{company_id}"
    await redis.publish(channel, json.dumps(message))


async def get_active_connections(company_id: int) -> int:
    """Get number of active WebSocket connections for a company"""
    redis = await get_redis_client()
    count_key = f"ws_connections:company:{company_id}:count"
    count = await redis.get(count_key)
    return int(count) if count else 0
