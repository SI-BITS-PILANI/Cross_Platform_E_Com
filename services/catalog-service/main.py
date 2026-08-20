"""Catalog Service — owns the product catalog.

Responsibilities:
  * Manage products (CRUD-lite) and stock levels.
  * Serve product data over REST to the API Gateway / GraphQL composition.
  * Serve a gRPC contract used by the Order Service to validate & price baskets.

Exposes BOTH a REST API (port 8001) and a gRPC server (port 50051) from one
process; the gRPC server is started as a task on the FastAPI event loop.
"""
import re
import uuid
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, Query

from database import products_collection
from grpc_server import serve_grpc
from models import ProductCreate
from seed import seed_products

grpc_server = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    await seed_products()
    global grpc_server
    grpc_server = await serve_grpc()
    yield
    if grpc_server is not None:
        await grpc_server.stop(grace=2)


app = FastAPI(title="Catalog Service", version="1.1.0", lifespan=lifespan)


def default_image_url(doc: dict) -> str:
    category = str(doc.get("category", "product")).replace("_", "-")
    return f"asset:products/{category}.png"


def serialize(doc: dict) -> dict:
    discount_percent = int(doc.get("discount_percent", 0))
    price = float(doc["price"])
    discount_factor = max(0, min(discount_percent, 90)) / 100
    final_price = round(price * (1 - discount_factor), 2)

    return {
        "product_id": doc["product_id"],
        "name": doc["name"],
        "description": doc.get("description", ""),
        "price": price,
        "final_price": final_price,
        "stock": doc["stock"],
        "category": doc.get("category", "general"),
        "brand": doc.get("brand", "ShopEase"),
        "rating": float(doc.get("rating", 4.3)),
        "reviews_count": int(doc.get("reviews_count", 0)),
        "discount_percent": discount_percent,
        "image_url": doc.get("image_url", default_image_url(doc)),
        "available": doc["stock"] > 0,
    }


@app.get("/health")
async def health():
    return {"status": "ok", "service": "catalog-service"}


# ----------------------------- API v1 -------------------------------------
@app.get("/api/v1/products")
async def list_products():
    docs = await products_collection.find().to_list(1000)
    return [serialize(d) for d in docs]


@app.post("/api/v1/products", status_code=201)
async def create_product(payload: ProductCreate):
    pid = "p-" + uuid.uuid4().hex[:8]
    doc = payload.model_dump()
    doc["product_id"] = pid
    await products_collection.insert_one(doc)
    return serialize(doc)


# ----------------------------- API v2 -------------------------------------
# Demonstrates NON-breaking, additive evolution: v2 keeps every v1 field and
# ADDS `currency` and `price_display`. v1 clients are unaffected and keep
# calling /api/v1; v2-aware clients opt in to the richer representation.
@app.get("/api/v2/products")
async def list_products_v2():
    docs = await products_collection.find().to_list(1000)
    out = []
    for d in docs:
        s = serialize(d)
        s["currency"] = "USD"
        s["price_display"] = f"${d['price']:.2f}"
        out.append(s)
    return out


# ----------------------------- Search & Filter API -------------------------
@app.get("/api/v1/products/search")
async def search_products(
    q: Optional[str] = Query(None, description="Search query for name, description, brand"),
    category: Optional[str] = Query(None, description="Filter by category"),
    brand: Optional[str] = Query(None, description="Filter by brand (comma-separated for multiple)"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price"),
    min_rating: Optional[float] = Query(None, ge=0, le=5, description="Minimum rating"),
    in_stock: Optional[bool] = Query(None, description="Only show in-stock items"),
    has_discount: Optional[bool] = Query(None, description="Only show discounted items"),
    sort_by: Optional[str] = Query(None, description="Sort field: price, rating, name, discount"),
    sort_order: Optional[str] = Query("asc", description="Sort order: asc or desc"),
    limit: int = Query(100, ge=1, le=500, description="Max results"),
    offset: int = Query(0, ge=0, description="Skip results for pagination"),
):
    """Advanced search and filter endpoint for products."""
    query_filter: dict = {}

    # Text search across name, description, brand
    if q:
        regex = re.compile(re.escape(q), re.IGNORECASE)
        query_filter["$or"] = [
            {"name": {"$regex": regex}},
            {"description": {"$regex": regex}},
            {"brand": {"$regex": regex}},
        ]

    # Category filter
    if category and category.lower() != "all":
        query_filter["category"] = {"$regex": re.compile(f"^{re.escape(category)}$", re.IGNORECASE)}

    # Brand filter (supports multiple brands comma-separated)
    if brand:
        brands = [b.strip() for b in brand.split(",") if b.strip()]
        if len(brands) == 1:
            query_filter["brand"] = {"$regex": re.compile(f"^{re.escape(brands[0])}$", re.IGNORECASE)}
        elif len(brands) > 1:
            query_filter["brand"] = {"$in": [re.compile(f"^{re.escape(b)}$", re.IGNORECASE) for b in brands]}

    # Price range filter
    if min_price is not None or max_price is not None:
        price_filter = {}
        if min_price is not None:
            price_filter["$gte"] = min_price
        if max_price is not None:
            price_filter["$lte"] = max_price
        query_filter["price"] = price_filter

    # Rating filter
    if min_rating is not None:
        query_filter["rating"] = {"$gte": min_rating}

    # In-stock filter
    if in_stock is True:
        query_filter["stock"] = {"$gt": 0}

    # Discount filter
    if has_discount is True:
        query_filter["discount_percent"] = {"$gt": 0}

    # Sorting
    sort_field_map = {
        "price": "price",
        "rating": "rating",
        "name": "name",
        "discount": "discount_percent",
    }
    sort_field = sort_field_map.get(sort_by, "name")
    sort_direction = -1 if sort_order == "desc" else 1

    # Execute query
    cursor = products_collection.find(query_filter)
    cursor = cursor.sort(sort_field, sort_direction)
    cursor = cursor.skip(offset).limit(limit)

    docs = await cursor.to_list(limit)
    
    # Get total count for pagination
    total_count = await products_collection.count_documents(query_filter)

    return {
        "products": [serialize(d) for d in docs],
        "total": total_count,
        "limit": limit,
        "offset": offset,
    }


@app.get("/api/v1/brands")
async def list_brands():
    """Get all unique brands for filtering."""
    brands = await products_collection.distinct("brand")
    return sorted(brands)


@app.get("/api/v1/categories")
async def list_categories():
    """Get all unique categories for filtering."""
    categories = await products_collection.distinct("category")
    return sorted(categories)


@app.get("/api/v1/price-range")
async def get_price_range():
    """Get min and max prices across all products."""
    pipeline = [
        {
            "$group": {
                "_id": None,
                "min_price": {"$min": "$price"},
                "max_price": {"$max": "$price"},
            }
        }
    ]
    result = await products_collection.aggregate(pipeline).to_list(1)
    if result:
        return {
            "min_price": result[0]["min_price"],
            "max_price": result[0]["max_price"],
        }
    return {"min_price": 0, "max_price": 0}


@app.get("/api/v1/products/{product_id}")
async def get_product(product_id: str):
    doc = await products_collection.find_one({"product_id": product_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Product not found")
    return serialize(doc)
