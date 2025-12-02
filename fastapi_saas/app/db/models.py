from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, JSON, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
from app.db.base import Base

class Plan(Base):
    __tablename__ = "plans"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    price = Column(Integer) # In cents
    features = Column(JSON)

class Company(Base):
    __tablename__ = "companies"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(Text, nullable=False)
    db_name = Column(Text, nullable=False, unique=True)
    odoo_host = Column(Text, nullable=False)
    plan_id = Column(Integer, ForeignKey("plans.id"))
    status = Column(Text, default="trial")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    users = relationship("User", back_populates="company")
    branches = relationship("Branch", back_populates="company")

class Branch(Base):
    __tablename__ = "branches"
    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"))
    name = Column(Text, nullable=False)
    code = Column(Text)
    location = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    company = relationship("Company", back_populates="branches")

class Role(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True)
    permissions = Column(JSON)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"))
    email = Column(Text, unique=True, nullable=False, index=True)
    full_name = Column(Text)
    password_hash = Column(Text, nullable=True)
    google_sub = Column(Text, nullable=True)
    default_branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    company = relationship("Company", back_populates="users")
    roles = relationship("Role", secondary="user_roles")

class UserRole(Base):
    __tablename__ = "user_roles"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    role_id = Column(Integer, ForeignKey("roles.id"), primary_key=True)

class AuditLog(Base):
    __tablename__ = "audit_logs"
    id = Column(Integer, primary_key=True, index=True)
    actor_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False, index=True)
    action = Column(String(100), nullable=False)  # e.g., "po.create", "grn.receive"
    resource_type = Column(String(50), nullable=False)  # e.g., "purchase_order"
    resource_id = Column(String(100), nullable=False)  # global id or odoo id
    client_event_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    payload = Column(JSON)
    meta = Column(JSON)  # e.g., {"correlation_id": "...", "odoo_call": "create"}
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

class EventProcessed(Base):
    __tablename__ = "events_processed"
    client_event_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    event_type = Column(String(50), nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending|processed|failed
    result = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True, onupdate=datetime.utcnow)

class RefreshToken(Base):
    """
    Stateful refresh token model for enterprise-grade authentication.
    Stores hashed tokens (not raw) for security.
    """
    __tablename__ = "refresh_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    token_hash = Column(String(255), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    revoked = Column(Boolean, default=False, nullable=False, index=True)
    revoked_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_used_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Optional metadata for security auditing
    device_fingerprint = Column(String(255), nullable=True)
    ip_address = Column(String(45), nullable=True)  # IPv6 max length
    user_agent = Column(Text, nullable=True)
    
    user = relationship("User", backref="refresh_tokens")
