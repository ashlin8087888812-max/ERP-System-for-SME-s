from celery import Celery
from app.config import settings
from app.odoo_client.client import odoo_client
from app.db.base import SessionLocal
from app.db import models
from app.db.idempotency import mark_processed, mark_failed, get_event_status
from app.db.audit import write_audit
import logging
from uuid import UUID
from datetime import datetime

# Initialize Celery with Redis separation
celery_app = Celery(
    "worker",
    broker=settings.redis_celery_broker_url,
    backend=settings.redis_celery_result_url
)

celery_app.conf.task_routes = {
    "app.workers.celery_app.persist_po_to_odoo": "main-queue",
    "app.workers.celery_app.persist_grn_to_odoo": "main-queue",
    "app.workers.celery_app.persist_transfer_to_odoo": "main-queue",
}

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=3)
def persist_po_to_odoo(self, client_event_id: str, tenant: dict, user_id: int, po_data: dict):
    """
    Persist Purchase Order to Odoo with tenant context.
    
    Args:
        client_event_id: UUID for idempotency
        tenant: Tenant context dict with company_id, db_name, odoo_host
        user_id: User ID who initiated the action
        po_data: Purchase order data
    """
    db = SessionLocal()
    event_uuid = UUID(client_event_id)
    
    try:
        # Re-check idempotency (worker-side check)
        existing = get_event_status(db, event_uuid)
        if existing and existing["status"] == "processed":
            logger.info(f"Event {client_event_id} already processed")
            return existing["result"]
        
        # Extract tenant info
        company_id = tenant["company_id"]
        db_name = tenant["db_name"]
        odoo_host = tenant["odoo_host"]
        
        # Call Odoo to create Purchase Order
        odoo_po_id = odoo_client.execute_kw(
            db_name=db_name,
            odoo_host=odoo_host,
            model='purchase.order',
            method='create',
            args=[po_data],
            kwargs={}
        )
        
        result = {
            "odoo_po_id": odoo_po_id,
            "status": "created",
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Mark event as processed
        mark_processed(db, event_uuid, result)
        
        # Write audit log
        write_audit(
            session=db,
            actor_user_id=user_id,
            company_id=company_id,
            action="po.create",
            resource_type="purchase_order",
            resource_id=str(odoo_po_id),
            client_event_id=event_uuid,
            payload=po_data,
            meta={
                "odoo_call": "create",
                "odoo_db": db_name,
                "task_id": self.request.id
            }
        )
        
        logger.info(f"PO created in Odoo: {odoo_po_id} for company {company_id}")
        return result
        
    except Exception as e:
        logger.error(f"Error persisting PO to Odoo: {e}")
        
        # Mark as failed
        mark_failed(db, event_uuid, str(e))
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=2 ** self.request.retries)
        
    finally:
        db.close()


@celery_app.task(bind=True, max_retries=3)
def persist_grn_to_odoo(self, client_event_id: str, tenant: dict, user_id: int, grn_data: dict):
    """
    Persist GRN (Goods Receipt Note) to Odoo with tenant context.
    
    Args:
        client_event_id: UUID for idempotency
        tenant: Tenant context dict
        user_id: User ID
        grn_data: GRN data
    """
    db = SessionLocal()
    event_uuid = UUID(client_event_id)
    
    try:
        # Re-check idempotency
        existing = get_event_status(db, event_uuid)
        if existing and existing["status"] == "processed":
            return existing["result"]
        
        company_id = tenant["company_id"]
        db_name = tenant["db_name"]
        odoo_host = tenant["odoo_host"]
        
        # Call Odoo to process GRN
        odoo_picking_id = odoo_client.execute_kw(
            db_name=db_name,
            odoo_host=odoo_host,
            model='stock.picking',
            method='button_validate',
            args=[grn_data.get("picking_id")],
            kwargs={}
        )
        
        result = {
            "odoo_picking_id": odoo_picking_id,
            "status": "validated",
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Mark processed
        mark_processed(db, event_uuid, result)
        
        # Audit log
        write_audit(
            session=db,
            actor_user_id=user_id,
            company_id=company_id,
            action="grn.receive",
            resource_type="stock_picking",
            resource_id=str(odoo_picking_id),
            client_event_id=event_uuid,
            payload=grn_data,
            meta={"odoo_call": "button_validate", "odoo_db": db_name}
        )
        
        # Invalidate inventory cache after GRN
        from app.cache.inventory import invalidate_inventory
        import asyncio
        asyncio.run(invalidate_inventory(company_id))
        
        logger.info(f"GRN processed in Odoo: {odoo_picking_id}")
        return result
        
    except Exception as e:
        logger.error(f"Error persisting GRN: {e}")
        mark_failed(db, event_uuid, str(e))
        raise self.retry(exc=e, countdown=2 ** self.request.retries)
        
    finally:
        db.close()


@celery_app.task(bind=True, max_retries=3)
def persist_transfer_to_odoo(self, client_event_id: str, tenant: dict, user_id: int, transfer_data: dict):
    """
    Persist internal transfer to Odoo with tenant context.
    """
    db = SessionLocal()
    event_uuid = UUID(client_event_id)
    
    try:
        existing = get_event_status(db, event_uuid)
        if existing and existing["status"] == "processed":
            return existing["result"]
        
        company_id = tenant["company_id"]
        db_name = tenant["db_name"]
        odoo_host = tenant["odoo_host"]
        
        # Create internal transfer in Odoo
        odoo_transfer_id = odoo_client.execute_kw(
            db_name=db_name,
            odoo_host=odoo_host,
            model='stock.picking',
            method='create',
            args=[transfer_data],
            kwargs={}
        )
        
        result = {
            "odoo_transfer_id": odoo_transfer_id,
            "status": "created"
        }
        
        mark_processed(db, event_uuid, result)
        
        write_audit(
            session=db,
            actor_user_id=user_id,
            company_id=company_id,
            action="transfer.create",
            resource_type="stock_picking",
            resource_id=str(odoo_transfer_id),
            client_event_id=event_uuid,
            payload=transfer_data,
            meta={"odoo_call": "create", "odoo_db": db_name}
        )
        
        # Invalidate inventory cache
        from app.cache.inventory import invalidate_inventory
        import asyncio
        asyncio.run(invalidate_inventory(company_id))
        
        return result
        
    except Exception as e:
        logger.error(f"Error persisting transfer: {e}")
        mark_failed(db, event_uuid, str(e))
        raise self.retry(exc=e, countdown=2 ** self.request.retries)
        
    finally:
        db.close()
