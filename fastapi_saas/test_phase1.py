# Test script for FastAPI Phase 1 improvements
# Run with: python test_phase1.py

import requests
import json
import uuid

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint and correlation ID"""
    print("\n=== Testing Health Endpoint ===")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print(f"Correlation ID: {response.headers.get('x-correlation-id')}")
    assert response.status_code == 200
    assert 'x-correlation-id' in response.headers
    print("✅ Health check passed")

def test_login():
    """Test authentication"""
    print("\n=== Testing Login ===")
    response = requests.post(
        f"{BASE_URL}/api/v1/auth/login",
        json={"email": "test@example.com", "password": "password123"}
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Token received: {data.get('access_token')[:50]}...")
        return data.get('access_token')
    else:
        print(f"Error: {response.text}")
        return None

def test_protected_endpoint(token):
    """Test protected endpoint with tenant context"""
    print("\n=== Testing Protected Endpoint ===")
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/v1/scm/test", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print(f"Correlation ID: {response.headers.get('x-correlation-id')}")

def test_idempotency(token):
    """Test idempotency with duplicate client_event_id"""
    print("\n=== Testing Idempotency ===")
    headers = {"Authorization": f"Bearer {token}"}
    event_id = str(uuid.uuid4())
    
    payload = {
        "client_event_id": event_id,
        "supplier": "ABC Corp",
        "total": 1000
    }
    
    # First request
    print(f"First request with event_id: {event_id}")
    response1 = requests.post(
        f"{BASE_URL}/api/v1/scm/purchase-orders",
        headers=headers,
        json=payload
    )
    print(f"Status: {response1.status_code}")
    print(f"Response: {response1.json()}")
    
    # Second request (duplicate)
    print(f"\nSecond request with same event_id: {event_id}")
    response2 = requests.post(
        f"{BASE_URL}/api/v1/scm/purchase-orders",
        headers=headers,
        json=payload
    )
    print(f"Status: {response2.status_code}")
    print(f"Response: {response2.json()}")
    print("✅ Should return existing result without re-processing")

if __name__ == "__main__":
    print("=" * 60)
    print("FastAPI Phase 1 - Integration Tests")
    print("=" * 60)
    
    # Test 1: Health check
    test_health()
    
    # Test 2: Login
    token = test_login()
    
    if token:
        # Test 3: Protected endpoint with tenant context
        test_protected_endpoint(token)
        
        # Test 4: Idempotency
        test_idempotency(token)
    
    print("\n" + "=" * 60)
    print("Tests Complete!")
    print("=" * 60)
