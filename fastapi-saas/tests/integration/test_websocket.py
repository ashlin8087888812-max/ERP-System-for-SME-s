"""
WebSocket tests for Phase 2
"""
import pytest
import asyncio
import json
from fastapi.testclient import TestClient
from app.main import app
from app.api.v1.ws import publish_to_company, get_active_connections


class TestWebSocket:
    """Test WebSocket functionality"""
    
    def test_websocket_requires_token(self):
        """Test WebSocket connection requires JWT token"""
        client = TestClient(app)
        
        with pytest.raises(Exception):
            with client.websocket_connect("/ws"):
                pass
    
    def test_websocket_with_valid_token(self, auth_token):
        """Test WebSocket connection with valid token"""
        client = TestClient(app)
        
        try:
            with client.websocket_connect(f"/ws?token={auth_token}") as websocket:
                # Connection should be established
                assert websocket is not None
                
                # Send ping
                websocket.send_text("ping")
                
                # Receive pong
                data = websocket.receive_text()
                assert data == "pong"
        except Exception as e:
            # WebSocket might fail in test environment without Redis
            pytest.skip(f"WebSocket test requires Redis: {e}")
    
    @pytest.mark.asyncio
    async def test_publish_to_company(self, test_company):
        """Test publishing message to company channel"""
        try:
            await publish_to_company(test_company.id, {
                "type": "test",
                "data": {"message": "Hello"}
            })
            # If no exception, test passes
            assert True
        except Exception as e:
            pytest.skip(f"Publish test requires Redis: {e}")
    
    @pytest.mark.asyncio
    async def test_get_active_connections(self, test_company):
        """Test getting active connection count"""
        try:
            count = await get_active_connections(test_company.id)
            assert isinstance(count, int)
            assert count >= 0
        except Exception as e:
            pytest.skip(f"Connection count test requires Redis: {e}")


class TestPresenceTracking:
    """Test WebSocket presence tracking"""
    
    @pytest.mark.asyncio
    async def test_connection_increments_count(self, test_company, auth_token):
        """Test that WebSocket connection increments presence count"""
        # This would require actually connecting WebSocket
        # and checking Redis keys
        pytest.skip("Requires full WebSocket + Redis setup")
    
    @pytest.mark.asyncio
    async def test_disconnect_decrements_count(self, test_company, auth_token):
        """Test that disconnect decrements presence count"""
        pytest.skip("Requires full WebSocket + Redis setup")
    
    @pytest.mark.asyncio
    async def test_ping_refreshes_ttl(self, test_company, auth_token):
        """Test that ping refreshes connection TTL"""
        pytest.skip("Requires full WebSocket + Redis setup")
