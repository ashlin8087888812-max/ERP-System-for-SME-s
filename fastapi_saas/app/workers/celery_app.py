from celery import Celery
from celery.signals import (
    task_prerun, task_postrun, task_failure,
    worker_ready, worker_shutdown
)
import logging
from uuid import UUID
from datetime import datetime

from app.config import settings
from app.odoo_client.client import odoo_client
from app.db.base import SessionLocal
from app.db import models
from app.db.idempotency import mark_processed, mark_failed, get_event_status
from app.db.audit import write_audit

# Initialize enterprise logging for Celery
from app.core.logging import logger

celery_app = Celery(
    settings.PROJECT_NAME,
    broker=settings.redis_celery_broker_url,
    backend=settings.redis_celery_result_url
)

celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)


# === CELERY EVENT LOGGING ===

@worker_ready.connect
def worker_ready_handler(sender, **kwargs):
    """Log when Celery worker starts."""
    logger.info(
        "Celery worker started",
        extra={
            "worker_id": sender.hostname,
            "environment": settings.ENVIRONMENT,
        }
    )


@worker_shutdown.connect
def worker_shutdown_handler(sender, **kwargs):
    """Log when Celery worker shuts down."""
    logger.info(
        "Celery worker shutting down",
        extra={"worker_id": sender.hostname}
    )


@task_prerun.connect
def task_prerun_handler(sender, task_id, task, args, kwargs, **extra):
    """Log before task execution."""
    logger.info(
        f"Task started: {task.name}",
        extra={
            "task_id": task_id,
            "task_name": task.name,
            "task_args": str(args)[:200],  # Truncate for safety
        }
    )


@task_postrun.connect
def task_postrun_handler(sender, task_id, task, args, kwargs, retval, **extra):
    """Log after successful task execution."""
    logger.info(
        f"Task completed: {task.name}",
        extra={
            "task_id": task_id,
            "task_name": task.name,
            "task_result": str(retval)[:200] if retval else None,
        }
    )


@task_failure.connect
def task_failure_handler(sender, task_id, exception, args, kwargs, traceback, einfo, **extra):
    """Log task failures."""
    logger.error(
        f"Task failed: {sender.name}",
        extra={
            "task_id": task_id,
            "task_name": sender.name,
            "exception_type": type(exception).__name__,
            "exception_message": str(exception),
        },
        exc_info=True
    )


# === CELERY TASKS ===


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


# === REFRESH TOKEN CLEANUP TASK ===

@celery_app.task(name="cleanup_expired_refresh_tokens")
def cleanup_expired_refresh_tokens():
    """
    Clean up expired refresh tokens from the database.
    
    Runs daily via Celery Beat to prevent database bloat.
    Only deletes tokens that have passed their expiration date.
    """
    from app.db.crud_refresh_token import delete_expired_tokens
    
    db = SessionLocal()
    try:
        deleted_count = delete_expired_tokens(db)
        
        logger.info(
            "Refresh token cleanup completed",
            extra={
                "deleted_count": deleted_count,
                "task_name": "cleanup_expired_refresh_tokens"
            }
        )
        
        return {
            "deleted_count": deleted_count,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(
            "Refresh token cleanup failed",
            extra={
                "error": str(e),
                "task_name": "cleanup_expired_refresh_tokens"
            }
        )
        raise
        
    finally:
        db.close()


# === CELERY BEAT SCHEDULE ===
# Configure periodic tasks

from celery.schedules import crontab

celery_app.conf.beat_schedule = {
    'cleanup-expired-refresh-tokens': {
        'task': 'cleanup_expired_refresh_tokens',
        'schedule': crontab(hour=2, minute=0),  # Run daily at 2 AM UTC
    },
}
