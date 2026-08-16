"""Seed the catalog with demo products on first start (idempotent)."""
from database import products_collection

SEED_PRODUCTS = [
    {"product_id": "p1001", "name": "14\" Ultrabook Laptop", "description": "16GB RAM, 512GB SSD",
    "price": 1099.00, "stock": 25, "category": "computers", "brand": "NovaTech", "rating": 4.7,
        "reviews_count": 483, "discount_percent": 12, "image_url": "asset:products/ultrabook.png"},
    {"product_id": "p1002", "name": "Wireless Mouse", "description": "Ergonomic, 2.4GHz",
    "price": 24.99, "stock": 200, "category": "accessories", "brand": "ClickPro", "rating": 4.4,
        "reviews_count": 1291, "discount_percent": 5, "image_url": "asset:products/wireless_mouse.png"},
    {"product_id": "p1003", "name": "Mechanical Keyboard", "description": "RGB, blue switches",
    "price": 79.50, "stock": 120, "category": "accessories", "brand": "TypeForge", "rating": 4.8,
        "reviews_count": 842, "discount_percent": 15, "image_url": "asset:products/mechanical_keyboard.png"},
    {"product_id": "p1004", "name": "27\" 4K Monitor", "description": "IPS, USB-C",
    "price": 329.00, "stock": 40, "category": "computers", "brand": "ViewLuxe", "rating": 4.6,
        "reviews_count": 366, "discount_percent": 10, "image_url": "asset:products/monitor_4k.png"},
    {"product_id": "p1005", "name": "Noise-Cancelling Headphones", "description": "Over-ear, BT 5.3",
    "price": 199.99, "stock": 60, "category": "audio", "brand": "SonicArc", "rating": 4.9,
        "reviews_count": 2270, "discount_percent": 20, "image_url": "asset:products/headphones.png"},
    {"product_id": "p1006", "name": "USB-C Hub", "description": "7-in-1 docking",
    "price": 45.00, "stock": 150, "category": "accessories", "brand": "DockHub", "rating": 4.3,
        "reviews_count": 590, "discount_percent": 8, "image_url": "asset:products/usb_hub.png"},
]


async def seed_products() -> None:
    count = await products_collection.count_documents({})
    if count == 0:
        await products_collection.insert_many([dict(p) for p in SEED_PRODUCTS])
        print(f"[catalog] seeded {len(SEED_PRODUCTS)} products")
    else:
        for product in SEED_PRODUCTS:
            await products_collection.update_one(
                {"product_id": product["product_id"]},
                {"$set": product},
                upsert=True,
            )
        print(f"[catalog] refreshed merchandising metadata for {len(SEED_PRODUCTS)} products")
