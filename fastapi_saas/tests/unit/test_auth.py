def test_signup(client):
    response = client.post(
        "/api/v1/auth/signup",
        json={
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User",
            "company_name": "Test Company",
            "company_db_name": "test_db"
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

def test_login(client):
    # Ensure user exists (signup first if running isolated, but module scope fixture persists)
    # For simplicity, we rely on the previous test or create a user here if needed.
    # But since tests run in order or random, better to be explicit.
    
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "password": "password123"
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
