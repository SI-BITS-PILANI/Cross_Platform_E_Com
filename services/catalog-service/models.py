"""Pydantic models / schemas for the Catalog Service."""
from pydantic import BaseModel, Field


class ProductCreate(BaseModel):
    name: str = Field(..., examples=["Mechanical Keyboard"])
    description: str = ""
    price: float = Field(..., gt=0)
    stock: int = Field(..., ge=0)
    category: str = "general"
    brand: str = "ShopEase"
    rating: float = Field(default=4.3, ge=0, le=5)
    reviews_count: int = Field(default=0, ge=0)
    discount_percent: int = Field(default=0, ge=0, le=90)
    image_url: str = ""


class Product(ProductCreate):
    product_id: str
    available: bool
