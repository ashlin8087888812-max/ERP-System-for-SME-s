"""
Integration tests for refresh token functionality.

Tests the complete enterprise-grade stateful refresh token flow:
- Login returns both tokens
- Refresh endpoint validates and rotates tokens
- Strict rotation prevents token reuse
- Logout revokes specific token (Option B)
- Logout-all revokes all user tokens
"""
import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timedelta
from app.main import app
from app.db.base import SessionLocal
from app.db import models, crud
from app.core import security
from app.db import crud_refresh_token
from app.config import settings

client = TestClient(app)


@pytest.fixture(scope="module")
def test_db():
    """Provide a database session for tests."""
    db = SessionLocal()
    yield db
    db.close()


@pytest.fixture(scope="module")
def test_user(test_db):
    """Create a test user for refresh token tests."""
    # Clean up existing test user/company
    existing_user = crud.get_user_by_email(test_db, "refresh@test.com")
    if existing_user:
        test_db.delete(existing_user)
        test_db.commit()
    
    existing_company = crud.get_company_by_name(test_db, "Refresh Test Co")
    if existing_company:
        test_db.delete(existing_company)
        test_db.commit()
    
    # Create fresh test company and user
    company = crud.create_company(
        db=test_db,
        name="Refresh Test Co",
        db_name="refresh_test_db"
    )
    
    user = crud.create_user(
        db=test_db,
        email="refresh@test.com",
        full_name="Refresh Test User",
        company_id=company.id,
        password_hash=security.get_password_hash("testpass123")
    )
    
    return user


class TestRefreshTokenFlow:
    """Test suite for refresh token functionality."""
    
    def test_login_returns_both_tokens(self, test_user):
        """Test that login returns both access and refresh tokens."""
        response = client.post(
            "/api/v1/auth/login",
            json={
                "email": "refresh@test.com",
                "password": "testpass123"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "access_token" in data
        assert "refresh_token" in data
        assert "token_type" in data
        assert "expires_in" in data
        
        # Verify token format
        assert data["token_type"] == "bearer"
        assert data["refresh_token"].startswith("rt_")
        assert data["expires_in"] == settings.JWT_EXP_MINUTES * 60
    
    def test_refresh_token_valid(self, test_user, test_db):
        """Test that refresh endpoint works with valid token."""
        # Login to get tokens
        login_response = client.post(
            "/api/v1/auth/login",
            json={
                "email": "refresh@test.com",
                "password": "testpass123"
            }
        )
        
        refresh_token = login_response.json()["refresh_token"]
        old_access_token = login_response.json()["access_token"]
        
        # Wait a moment to ensure new token is different
        import time
        time.sleep(1)
        
        # Use refresh token to get new access token
        refresh_response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )
        
        assert refresh_response.status_code == 200
        refresh_data = refresh_response.json()
        
        # Verify new tokens returned
        assert "access_token" in refresh_data
        assert "refresh_token" in refresh_data
        
        # Verify new tokens are different (rotation)
        assert refresh_data["access_token"] != old_access_token
        assert refresh_data["refresh_token"] != refresh_token
    
    def test_refresh_token_rotation_prevents_reuse(self, test_user):
        """Test that strict rotation prevents old token reuse."""
        # Login
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": "refresh@test.com", "password": "testpass123"}
        )
        
        old_refresh_token = login_response.json()["refresh_token"]
        
        # Use refresh token (this should rotate it)
        refresh_response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh_token}
        )
        
        assert refresh_response.status_code == 200
        
        # Try to reuse old refresh token (should fail)
        reuse_response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh_token}
        )
        
        assert reuse_response.status_code == 401
        assert "Invalid or expired" in reuse_response.json()["detail"]
    
    def test_refresh_token_expired(self, test_user, test_db):
        """Test that expired refresh tokens are rejected."""
        # Create an expired refresh token manually
        expired_token = security.generate_refresh_token()
        expired_time = datetime.utcnow() - timedelta(days=1)  # Yesterday
        
        crud_refresh_token.create_refresh_token(
            db=test_db,
            user_id=test_user.id,
            token=expired_token,
            expires_at=expired_time
        )
        
        # Try to use expired token
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": expired_token}
        )
        
        assert response.status_code == 401
        assert "Invalid or expired" in response.json()["detail"]
    
    def test_refresh_token_revoked(self, test_user, test_db):
        """Test that revoked refresh tokens are rejected."""
        # Create a valid refresh token
        valid_token = security.generate_refresh_token()
        future_time = datetime.utcnow() + timedelta(days=30)
        
        db_token = crud_refresh_token.create_refresh_token(
            db=test_db,
            user_id=test_user.id,
            token=valid_token,
            expires_at=future_time
        )
        
        # Revoke it
        crud_refresh_token.revoke_refresh_token(test_db, db_token.id)
        
        # Try to use revoked token
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": valid_token}
        )
        
        assert response.status_code == 401
        assert "Invalid or expired" in response.json()["detail"]
    
    def test_logout_revokes_token(self, test_user):
        """Test that logout revokes the refresh token (Option B)."""
        # Login
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": "refresh@test.com", "password": "testpass123"}
        )
        
        access_token = login_response.json()["access_token"]
        refresh_token = login_response.json()["refresh_token"]
        
        # Logout using access token
        logout_response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        
        assert logout_response.status_code == 200
        assert "Successfully logged out" in logout_response.json()["message"]
        
        # Try to use refresh token after logout (should fail)
        refresh_response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )
        
        assert refresh_response.status_code == 401
    
    def test_logout_all_revokes_all_tokens(self, test_user):
        """Test that logout-all revokes all user tokens."""
        # Login multiple times to create multiple tokens
        tokens = []
        for _ in range(3):
            response = client.post(
                "/api/v1/auth/login",
                json={"email": "refresh@test.com", "password": "testpass123"}
            )
            tokens.append({
                "access": response.json()["access_token"],
                "refresh": response.json()["refresh_token"]
            })
        
        # Logout from all devices using first access token
        logout_response = client.post(
            "/api/v1/auth/logout-all",
            headers={"Authorization": f"Bearer {tokens[0]['access']}"}
        )
        
        assert logout_response.status_code == 200
        data = logout_response.json()
        assert "revoked_count" in data
        assert data["revoked_count"] >= 3
        
        # Try to use any refresh token (all should fail)
        for token_pair in tokens:
            refresh_response = client.post(
                "/api/v1/auth/refresh",
                json={"refresh_token": token_pair["refresh"]}
            )
            assert refresh_response.status_code == 401
    
    def test_token_contains_rtid(self, test_user):
        """Test that access token contains rtid claim (Option B)."""
        from app.core import jwt
        
        # Login
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": "refresh@test.com", "password": "testpass123"}
        )
        
        access_token = login_response.json()["access_token"]
        
        # Decode JWT
        payload = jwt.decode_token(access_token)
        
        assert payload is not None
        assert "rtid" in payload
        assert isinstance(payload["rtid"], int)
    
    def test_cleanup_deletes_expired_tokens(self, test_user, test_db):
        """Test that cleanup task deletes expired tokens."""
        # Create some expired tokens
        for _ in range(3):
            expired_token = security.generate_refresh_token()
            crud_refresh_token.create_refresh_token(
                db=test_db,
                user_id=test_user.id,
                token=expired_token,
                expires_at=datetime.utcnow() - timedelta(days=1)
            )
        
        # Create a valid token
        valid_token = security.generate_refresh_token()
        crud_refresh_token.create_refresh_token(
            db=test_db,
            user_id=test_user.id,
            token=valid_token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        
        # Run cleanup
        deleted_count = crud_refresh_token.delete_expired_tokens(test_db)
        
        # At least 3 expired tokens should be deleted
        assert deleted_count >= 3
        
        # Valid token should still work
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": valid_token}
        )
        
        assert response.status_code == 200


class TestRefreshTokenSecurity:
    """Security-focused tests for refresh tokens."""
    
    def test_token_hash_stored_not_raw(self, test_user, test_db):
        """Test that only hashed tokens are stored in DB."""
        # Create a token
        raw_token = security.generate_refresh_token()
        future_time = datetime.utcnow() + timedelta(days=30)
        
        db_token = crud_refresh_token.create_refresh_token(
            db=test_db,
            user_id=test_user.id,
            token=raw_token,
            expires_at=future_time
        )
        
        # Verify raw token is NOT in database
        assert db_token.token_hash != raw_token
        
        # Verify hash can be verified
        assert security.verify_token_hash(raw_token, db_token.token_hash)
    
    def test_invalid_token_format_rejected(self):
        """Test that invalid token formats are rejected."""
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "invalid_token_format"}
        )
        
        assert response.status_code == 401
    
    def test_missing_authorization_header(self):
        """Test that logout fails without authorization header."""
        response = client.post("/api/v1/auth/logout")
        
        assert response.status_code == 401
        assert "Missing or invalid" in response.json()["detail"]
