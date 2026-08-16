"""Catalog Service — owns the product catalog.

Responsibilities:
  * Manage products (CRUD-lite) and stock levels.
  * Serve product data over REST to the API Gateway / GraphQL composition.
  * Serve a gRPC contract used by the Order Service to validate & price baskets.

Exposes BOTH a REST API (port 8001) and a gRPC server (port 50051) from one
process; the gRPC server is started as a task on the FastAPI event loop.
"""
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException

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


@app.get("/api/v1/products/{product_id}")
async def get_product(product_id: str):
    doc = await products_collection.find_one({"product_id": product_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Product not found")
    return serialize(doc)


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
