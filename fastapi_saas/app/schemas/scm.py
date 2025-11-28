"""
Enhanced Pydantic models with response validation and examples.
"""
from pydantic import BaseModel, Field, UUID4
from typing import List, Optional
from datetime import datetime


class PurchaseOrderLine(BaseModel):
    """Purchase order line item"""
    sku: str = Field(..., min_length=1, max_length=100, description="Product SKU")
    qty: int = Field(..., gt=0, description="Quantity (must be positive)")
    price_unit: float = Field(..., gt=0, description="Unit price")
    
    class Config:
        schema_extra = {
            "example": {
                "sku": "SKU-12345",
                "qty": 10,
                "price_unit": 25.50
            }
        }


class PurchaseOrderCreate(BaseModel):
    """Create purchase order request"""
    client_event_id: UUID4 = Field(..., description="Unique event ID for idempotency")
    po_ref: str = Field(..., min_length=1, max_length=100, description="PO reference number")
    items: List[PurchaseOrderLine] = Field(..., min_items=1, description="Order line items")
    notes: Optional[str] = Field(None, max_length=1000, description="Additional notes")
    
    class Config:
        schema_extra = {
            "example": {
                "client_event_id": "550e8400-e29b-41d4-a716-446655440000",
                "po_ref": "PO-2024-001",
                "items": [
                    {
                        "sku": "SKU-12345",
                        "qty": 10,
                        "price_unit": 25.50
                    },
                    {
                        "sku": "SKU-67890",
                        "qty": 5,
                        "price_unit": 15.00
                    }
                ],
                "notes": "Urgent delivery required"
            }
        }


class PurchaseOrderResponse(BaseModel):
    """Purchase order creation response"""
    status: str = Field(..., description="Task status (pending/processing/completed)")
    client_event_id: str = Field(..., description="Event ID for tracking")
    correlation_id: str = Field(..., description="Request correlation ID")
    task_id: Optional[str] = Field(None, description="Celery task ID")
    created_at: datetime = Field(..., description="Creation timestamp")
    
    class Config:
        schema_extra = {
            "example": {
                "status": "pending",
                "client_event_id": "550e8400-e29b-41d4-a716-446655440000",
                "correlation_id": "abc123-def456-ghi789",
                "task_id": "celery-task-123",
                "created_at": "2024-11-20T12:00:00Z"
            }
        }


class GRNCreate(BaseModel):
    """Goods Receipt Note creation request"""
    client_event_id: UUID4 = Field(..., description="Unique event ID for idempotency")
    po_ref: str = Field(..., min_length=1, max_length=100, description="Related PO reference")
    items: List[PurchaseOrderLine] = Field(..., min_items=1, description="Received items")
    received_date: Optional[datetime] = Field(None, description="Receipt date")
    
    class Config:
        schema_extra = {
            "example": {
                "client_event_id": "650e8400-e29b-41d4-a716-446655440001",
                "po_ref": "PO-2024-001",
                "items": [
                    {
                        "sku": "SKU-12345",
                        "qty": 10,
                        "price_unit": 25.50
                    }
                ],
                "received_date": "2024-11-20T10:30:00Z"
            }
        }


class ErrorResponse(BaseModel):
    """Standard error response"""
    error: str = Field(..., description="Error type")
    detail: str = Field(..., description="Error details")
    correlation_id: Optional[str] = Field(None, description="Request correlation ID")
    
    class Config:
        schema_extra = {
            "example": {
                "error": "ValidationError",
                "detail": "Invalid SKU format",
                "correlation_id": "abc123-def456-ghi789"
            }
        }
