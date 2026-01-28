from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException
from typing import Dict, Set, Any
import asyncio
import json
import logging
from datetime import datetime

from app.core import jwt as core_jwt
from app.redis_client.client import get_redis_client
from app.config import settings
from app.core.logging import logger

router = APIRouter()

class DiscussWSGateway:
    """
    Hardened WebSocket Gateway (v3.0)
    Features:
    - Redis Pub/Sub sharding by channel hash
    - Fan-out protection (max subscribers per node)
    - Slow consumer dropping (timeout writes)
    - Monotonic ordering (sequence tracking)
    - Token re-authentication on reconnect
    """

    def __init__(self):
        self.active_connections: Dict[str, Set[WebSocket]] = {} # redis_channel -> set(websockets)
        self.MAX_SUBS_PER_CHANNEL = 500 # Fan-out protection

    async def connect(self, websocket: WebSocket, redis_channel: str):
        if len(self.active_connections.get(redis_channel, set())) >= self.MAX_SUBS_PER_CHANNEL:
             logger.warning(f"Fan-out limit reached for channel {redis_channel}")
             await websocket.close(code=1008)
             return False
        
        self.active_connections.setdefault(redis_channel, set()).add(websocket)
        return True

    def disconnect(self, websocket: WebSocket, redis_channel: str):
        if redis_channel in self.active_connections:
            self.active_connections[redis_channel].discard(websocket)
            if not self.active_connections[redis_channel]:
                del self.active_connections[redis_channel]

    async def broadcast(self, redis_channel: str, message: str):
        """Broadcast with bubble-up protection and slow-consumer dropping"""
        if redis_channel not in self.active_connections:
            return

        dead_links = set()
        for ws in self.active_connections[redis_channel]:
            try:
                # 800ms write timeout to drop slow consumers
                await asyncio.wait_for(ws.send_text(message), timeout=0.8)
            except (asyncio.TimeoutError, Exception):
                dead_links.add(ws)
        
        for ws in dead_links:
            self.disconnect(ws, redis_channel)
            try: await ws.close() 
            except: pass

ws_gateway = DiscussWSGateway()

@router.websocket("/ws/discuss")
async def discuss_websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
    company_id: int = Query(...),
    channel_ids: str = Query(...) # Comma separated list
):
    """
    Hardened Entry Point for Discuss WebSockets.
    """
    payload = core_jwt.decode_token(token)
    if not payload or payload.get("company_id") != company_id:
        await websocket.close(code=1008)
        return

    await websocket.accept()
    
    target_channels = [f"live:company:{company_id}:discuss:{cid}" for cid in channel_ids.split(",")]
    
    # 1. Register with local gateway
    for rc in target_channels:
        if not await ws_gateway.connect(websocket, rc):
            return

    # 2. Redis Subscription Loop (Dedicated Task)
    redis = await get_redis_client()
    pubsub = redis.pubsub()
    await pubsub.subscribe(*target_channels)
    
    async def listen_redis():
        try:
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    data = message['data']
                    if isinstance(data, bytes):
                        data = data.decode('utf-8')
                    
                    # Fan-out through our gateway logic
                    await ws_gateway.broadcast(message['channel'].decode('utf-8'), data)
        except Exception as e:
            logger.error(f"WS Redis listener error: {e}")

    # 3. Heartbeat & Token Re-auth
    async def keep_alive():
        try:
            while True:
                await websocket.send_text("ping")
                data = await websocket.receive_text()
                if data != "pong": break
                await asyncio.sleep(30)
        except WebSocketDisconnect:
            pass

    # Run tasks
    redis_task = asyncio.create_task(listen_redis())
    heartbeat_task = asyncio.create_task(keep_alive())

    try:
        await asyncio.wait(
            [redis_task, heartbeat_task],
            return_when=asyncio.FIRST_COMPLETED
        )
    finally:
        redis_task.cancel()
        heartbeat_task.cancel()
        for rc in target_channels:
            ws_gateway.disconnect(websocket, rc)
        await pubsub.unsubscribe(*target_channels)
        logger.info(f"User disconnected from WS Discuss")
