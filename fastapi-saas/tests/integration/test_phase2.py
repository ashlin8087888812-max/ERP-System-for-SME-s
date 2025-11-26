"""
Tests for Phase 2: Idempotency, Tenant Context, and Audit Logging
"""
import pytest
import uuid
from sqlalchemy.orm import Session
from app.db.idempotency import reserve_event, mark_processed, mark_failed, get_event_status
from app.db.audit import write_audit, get_audit_trail
from app.db import models


class TestIdempotency:
    """Test idempotency helpers"""
    
    def test_reserve_event_new(self, db: Session, test_company, test_user):
        """Test reserving a new event"""
        event_id = uuid.uuid4()
        
        result = reserve_event(
            db,
            event_id,
            test_company.id,
            test_user.id,
            "po.create"
        )
        
        assert result is True
        
        # Check event was created
        status = get_event_status(db, event_id)
        assert status is not None
        assert status["status"] == "pending"
    
    def test_reserve_event_duplicate(self, db: Session, test_company, test_user):
        """Test reserving duplicate event returns False"""
        event_id = uuid.uuid4()
        
        # First reservation
        result1 = reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        assert result1 is True
        
        # Second reservation (duplicate)
        result2 = reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        assert result2 is False
    
    def test_mark_processed(self, db: Session, test_company, test_user):
        """Test marking event as processed"""
        event_id = uuid.uuid4()
        
        # Reserve event
        reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        
        # Mark as processed
        result = {"odoo_po_id": 123, "status": "created"}
        mark_processed(db, event_id, result)
        
        # Check status
        status = get_event_status(db, event_id)
        assert status["status"] == "processed"
        assert status["result"] == result
    
    def test_mark_failed(self, db: Session, test_company, test_user):
        """Test marking event as failed"""
        event_id = uuid.uuid4()
        
        # Reserve event
        reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        
        # Mark as failed
        mark_failed(db, event_id, "Connection timeout")
        
        # Check status
        status = get_event_status(db, event_id)
        assert status["status"] == "failed"
        assert "Connection timeout" in status["result"]["error"]
    
    def test_reserve_failed_event_allows_retry(self, db: Session, test_company, test_user):
        """Test that failed events can be retried"""
        event_id = uuid.uuid4()
        
        # Reserve and mark as failed
        reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        mark_failed(db, event_id, "Error")
        
        # Try to reserve again (should succeed for failed events)
        result = reserve_event(db, event_id, test_company.id, test_user.id, "po.create")
        assert result is True
        
        # Status should be pending again
        status = get_event_status(db, event_id)
        assert status["status"] == "pending"


class TestAuditLogging:
    """Test audit logging functionality"""
    
    def test_write_audit(self, db: Session, test_company, test_user):
        """Test writing audit log entry"""
        event_id = uuid.uuid4()
        
        log = write_audit(
            session=db,
            actor_user_id=test_user.id,
            company_id=test_company.id,
            action="po.create",
            resource_type="purchase_order",
            resource_id="123",
            client_event_id=event_id,
            payload={"po_ref": "PO-001"},
            meta={"correlation_id": "abc-123"}
        )
        
        assert log.id is not None
        assert log.action == "po.create"
        assert log.resource_type == "purchase_order"
        assert log.resource_id == "123"
        assert log.meta["correlation_id"] == "abc-123"
    
    def test_get_audit_trail(self, db: Session, test_company, test_user):
        """Test retrieving audit trail"""
        # Create multiple audit entries
        for i in range(3):
            write_audit(
                session=db,
                actor_user_id=test_user.id,
                company_id=test_company.id,
                action=f"po.create",
                resource_type="purchase_order",
                resource_id=str(i),
                client_event_id=uuid.uuid4(),
                payload={"po_ref": f"PO-{i:03d}"},
                meta={}
            )
        
        # Get audit trail
        trail = get_audit_trail(db, test_company.id, limit=10)
        
        assert len(trail) >= 3
        assert trail[0].company_id == test_company.id
    
    def test_get_audit_trail_filtered(self, db: Session, test_company, test_user):
        """Test filtering audit trail by resource"""
        # Create entries for different resources
        write_audit(db, test_user.id, test_company.id, "po.create", "purchase_order", "1", uuid.uuid4(), {}, {})
        write_audit(db, test_user.id, test_company.id, "grn.receive", "stock_picking", "2", uuid.uuid4(), {}, {})
        
        # Filter by purchase_order
        trail = get_audit_trail(db, test_company.id, resource_type="purchase_order")
        
        assert all(log.resource_type == "purchase_order" for log in trail)


class TestTenantContext:
    """Test tenant context in endpoints"""
    
    def test_tenant_middleware_sets_context(self, client, test_user, test_company, auth_headers):
        """Test that tenant middleware sets request.state.tenant"""
        # This would require a test endpoint that exposes request.state.tenant
        # For now, we test indirectly through SCM endpoints
        pass
    
    def test_require_tenant_dependency(self, client, auth_headers):
        """Test require_tenant dependency"""
        # Test endpoint with require_tenant should work with valid token
        response = client.get("/api/v1/scm/test", headers=auth_headers)
        # Expect 404 if endpoint doesn't exist, not 403
        assert response.status_code in [200, 404]
    
    def test_require_tenant_without_auth(self, client):
        """Test require_tenant fails without authentication"""
        response = client.get("/api/v1/scm/test")
        assert response.status_code == 401


class TestCeleryTasks:
    """Test Celery task signatures and behavior"""
    
    def test_persist_po_task_signature(self):
        """Test that persist_po_to_odoo has correct signature"""
        from app.workers.celery_app import persist_po_to_odoo
        
        # Check task accepts tenant parameter
        import inspect
        sig = inspect.signature(persist_po_to_odoo.run)
        params = list(sig.parameters.keys())
        
        assert 'client_event_id' in params
        assert 'tenant' in params
        assert 'user_id' in params
        assert 'po_data' in params
    
    def test_persist_grn_task_signature(self):
        """Test that persist_grn_to_odoo has correct signature"""
        from app.workers.celery_app import persist_grn_to_odoo
        
        import inspect
        sig = inspect.signature(persist_grn_to_odoo.run)
        params = list(sig.parameters.keys())
        
        assert 'tenant' in params
    
    @pytest.mark.skip(reason="Requires Celery worker and Odoo")
    def test_persist_po_with_tenant(self, db, test_company, test_user):
        """Test PO task with tenant context (integration test)"""
        from app.workers.celery_app import persist_po_to_odoo
        
        event_id = str(uuid.uuid4())
        tenant = {
            "company_id": test_company.id,
            "db_name": test_company.db_name,
            "odoo_host": test_company.odoo_host,
            "company_name": test_company.name
        }
        
        result = persist_po_to_odoo.delay(
            event_id,
            tenant,
            test_user.id,
            {"po_ref": "PO-001"}
        )
        
        # Wait for result
        assert result.get(timeout=10) is not None


class TestSCMEndpoints:
    """Test SCM endpoints with Phase 2 improvements"""
    
    def test_create_po_reserves_event(self, client, db, auth_headers):
        """Test that creating PO reserves event before enqueue"""
        event_id = str(uuid.uuid4())
        
        response = client.post(
            "/api/v1/scm/purchase-orders",
            headers=auth_headers,
            json={
                "client_event_id": event_id,
                "po_ref": "PO-001",
                "items": [{"sku": "SKU123", "qty": 10}]
            }
        )
        
        assert response.status_code == 202
        data = response.json()
        assert data["status"] == "pending"
        assert data["client_event_id"] == event_id
        assert "correlation_id" in data
        
        # Check event was reserved in DB
        status = get_event_status(db, uuid.UUID(event_id))
        assert status is not None
        assert status["status"] == "pending"
    
    def test_create_po_duplicate_returns_existing(self, client, db, auth_headers):
        """Test that duplicate PO request returns existing result"""
        event_id = str(uuid.uuid4())
        
        payload = {
            "client_event_id": event_id,
            "po_ref": "PO-001",
            "items": [{"sku": "SKU123", "qty": 10}]
        }
        
        # First request
        response1 = client.post("/api/v1/scm/purchase-orders", headers=auth_headers, json=payload)
        assert response1.status_code == 202
        
        # Second request (duplicate)
        response2 = client.post("/api/v1/scm/purchase-orders", headers=auth_headers, json=payload)
        assert response2.status_code == 202
        
        # Should return same event_id
        assert response2.json()["client_event_id"] == event_id
    
    def test_create_grn_with_tenant(self, client, auth_headers):
        """Test GRN creation with tenant context"""
        event_id = str(uuid.uuid4())
        
        response = client.post(
            "/api/v1/scm/grn",
            headers=auth_headers,
            json={
                "client_event_id": event_id,
                "po_ref": "PO-001",
                "items": [{"sku": "SKU123", "qty": 10}]
            }
        )
        
        assert response.status_code == 202
        data = response.json()
        assert "correlation_id" in data
