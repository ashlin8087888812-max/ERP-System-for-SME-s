import asyncio
import json
import httpx
import websockets
import sys

# Configuration
BASE_URL = "http://localhost:8000/api/v1"
WS_URL = "ws://localhost:8000/api/v1/ws"
EMAIL = "test@example.com"
PASSWORD = "password123"

async def verify_realtime():
    print(f"Authenticating as {EMAIL}...")
    async with httpx.AsyncClient() as client:
        # 1. Login
        response = await client.post(f"{BASE_URL}/auth/login", json={
            "email": EMAIL,
            "password": PASSWORD
        })
        
        if response.status_code != 200:
            print(f"Login failed: {response.text}")
            sys.exit(1)
            
        token = response.json()["access_token"]
        print("Login successful. Token received.")
        
        # 2. Connect to WebSocket
        ws_connect_url = f"{WS_URL}?token={token}"
        print(f"Connecting to WebSocket: {ws_connect_url}")
        
        try:
            async with websockets.connect(ws_connect_url) as websocket:
                print("WebSocket connected.")
                
                # 3. Create Contact via API
                print("Creating contact via API...")
                contact_data = {
                    "name": "Realtime Test Contact",
                    "email": "realtime@test.com",
                    "phone": "555-0199",
                    "company_name": "Test Corp"
                }
                
                # Run API call in background or just await it?
                # We need to be listening when the event comes.
                # So we should create a task for listening.
                
                async def listen_for_event():
                    print("Listening for events...")
                    try:
                        while True:
                            message = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                            data = json.loads(message)
                            print(f"Received WebSocket message: {data}")
                            
                            if data.get("type") == "model_updated" and \
                               data.get("model") == "res.partner" and \
                               data.get("action") == "create":
                                return True
                    except asyncio.TimeoutError:
                        print("Timeout waiting for event.")
                        return False
                
                listener_task = asyncio.create_task(listen_for_event())
                
                # Give the listener a moment to start
                await asyncio.sleep(1)
                
                # Create contact
                create_response = await client.post(
                    f"{BASE_URL}/contacts/",
                    json=contact_data,
                    headers={"Authorization": f"Bearer {token}"}
                )
                
                if create_response.status_code != 200:
                    print(f"Create contact failed: {create_response.text}")
                    listener_task.cancel()
                    sys.exit(1)
                
                print(f"Contact created. ID: {create_response.json()['id']}")
                
                # Wait for listener
                success = await listener_task
                
                if success:
                    print("SUCCESS: Real-time update verified!")
                    
                    # Cleanup: Delete the contact
                    contact_id = create_response.json()['id']
                    await client.delete(
                        f"{BASE_URL}/contacts/{contact_id}",
                        headers={"Authorization": f"Bearer {token}"}
                    )
                    print("Cleanup: Contact deleted.")
                    
                else:
                    print("FAILURE: Did not receive expected event.")
                    sys.exit(1)
                    
        except Exception as e:
            print(f"WebSocket error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    asyncio.run(verify_realtime())
