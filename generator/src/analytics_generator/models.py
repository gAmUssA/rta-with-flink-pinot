from datetime import datetime
from typing import Optional, Literal
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class BaseEvent(BaseModel):
    """Base event model that all other events inherit from."""
    event_id: UUID = Field(default_factory=uuid4)
    event_timestamp: datetime = Field(default_factory=datetime.utcnow)
    user_id: str
    session_id: str
    device_type: str
    os: str
    browser: str
    location: str


class PageViewEvent(BaseEvent):
    """Event generated when a user views a page."""
    event_type: Literal["page_view"] = "page_view"
    page_url: str
    referrer_url: Optional[str] = None
    time_spent: Optional[float] = None


class ProductViewEvent(BaseEvent):
    """Event generated when a user views a product."""
    event_type: Literal["product_view"] = "product_view"
    product_id: str
    product_name: str
    product_category: str
    price: float


class AddToCartEvent(BaseEvent):
    """Event generated when a user adds a product to their cart."""
    event_type: Literal["add_to_cart"] = "add_to_cart"
    product_id: str
    product_name: str
    product_category: str
    price: float
    quantity: int


class PurchaseEvent(BaseEvent):
    """Event generated when a user makes a purchase."""
    event_type: Literal["purchase"] = "purchase"
    order_id: str
    product_id: str
    product_name: str
    product_category: str
    price: float
    quantity: int
    total_amount: float