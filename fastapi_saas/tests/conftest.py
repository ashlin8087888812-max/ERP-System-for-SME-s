"""
Test fixtures for Phase 2 tests
"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from app.main import app
from app.db.base import Base, get_db
from app.db import models
from app.core.jwt import create_access_token
import asyncio


# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
from sqlalchemy.pool import StaticPool
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db():
    """Create test database session"""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db):
    """Create test client"""
    def override_get_db():
        try:
            yield db
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def test_company(db):
    """Create test company"""
    company = models.Company(
        name="Test Company",
        db_name="test_db",
        odoo_host="http://localhost:8068",
        status="active"
    )
    db.add(company)
    db.commit()
    db.refresh(company)
    return company


@pytest.fixture
def test_role(db):
    """Create test role"""
    role = models.Role(
        name="admin",
        permissions={"all": True}
    )
    db.add(role)
    db.commit()
    db.refresh(role)
    return role


@pytest.fixture
def test_user(db, test_company, test_role):
    """Create test user"""
    from app.core.security import get_password_hash
    user = models.User(
        email="test@example.com",
        full_name="Test User",
        company_id=test_company.id,
        password_hash=get_password_hash("password123"),
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Assign role
    user_role = models.UserRole(user_id=user.id, role_id=test_role.id)
    db.add(user_role)
    db.commit()
    
    return user


@pytest.fixture
def auth_token(test_user, test_company):
    """Generate JWT token for test user"""
    token = create_access_token({
        "sub": str(test_user.id),
        "email": test_user.email,
        "company_id": test_company.id,
        "role": "admin",
        "full_name": test_user.full_name
    })
    return token


@pytest.fixture
def auth_headers(auth_token):
    """Generate auth headers with JWT token"""
    return {"Authorization": f"Bearer {auth_token}"}


@pytest.fixture
async def redis_client():
    """Create a fresh Redis client for each test"""
    from app.config import settings
    import redis.asyncio as redis
    
    client = redis.from_url(settings.REDIS_URL, encoding="utf-8", decode_responses=True)
    try:
        await client.flushdb()
        yield client
    finally:
        await client.close()


@pytest.fixture(autouse=True)
def patch_redis(mocker, redis_client):
    """Patch get_redis_client to return the fresh client"""
    async def get_client_override():
        return redis_client
        
    mocker.patch("app.redis_client.client.get_redis_client", side_effect=get_client_override)
    mocker.patch("app.core.quotas.get_redis_client", side_effect=get_client_override)
    mocker.patch("app.core.usage_metering.get_redis_client", side_effect=get_client_override)
