"""
☁️ AWS Database Service — Aurora PostgreSQL & DynamoDB queries
✅ Production-ready: Connection pooling, proper async via to_thread, error handling
"""
import json
import math
import asyncio
import logging
from datetime import datetime, timedelta
from psycopg2.extras import RealDictCursor
from memory.aws_memory import get_aurora_connection, release_aurora_connection, get_dynamo_table

logger = logging.getLogger(__name__)


# ============================================================
# Helper: Run blocking DB call in thread pool (HIGH-04 Fix)
# ============================================================

def _execute_aurora_query(query_fn):
    """Execute a synchronous Aurora query function, managing connection lifecycle."""
    conn = get_aurora_connection()
    if not conn:
        return None
    try:
        return query_fn(conn)
    except Exception as e:
        logger.error(f"Aurora query error: {e}")
        return None
    finally:
        release_aurora_connection(conn)


# ============================================================
# Product Queries (Aurora PostgreSQL)
# ============================================================

async def search_products(query: str = None, category: str = None,
                          min_price: float = None, max_price: float = None,
                          bazaar_id: str = None, limit: int = 10) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            sql = 'SELECT id, name_ar AS "nameAr", name_en AS "nameEn", description_ar AS "descriptionAr", category_name AS category, price, old_price AS "oldPrice", rating, review_count AS "reviewCount", image_url AS "imageUrl", bazaar_name AS "bazaarName", bazaar_id AS "bazaarId", material, sizes FROM products WHERE 1=1'
            params = []

            if category:
                sql += " AND category_name = %s"
                params.append(category)
            if bazaar_id:
                sql += " AND bazaar_id = %s"
                params.append(bazaar_id)
            if min_price is not None:
                sql += " AND price >= %s"
                params.append(min_price)
            if max_price is not None:
                sql += " AND price <= %s"
                params.append(max_price)
            if query:
                sql += " AND (name_ar ILIKE %s OR description_ar ILIKE %s)"
                q = f"%{query}%"
                params.extend([q, q])

            sql += " LIMIT %s"
            params.append(limit)

            cur.execute(sql, params)
            rows = cur.fetchall()

            for row in rows:
                if row.get("sizes") and isinstance(row["sizes"], str):
                    try:
                        row["sizes"] = json.loads(row["sizes"])
                    except Exception:
                        row["sizes"] = [row["sizes"]]
            return [dict(r) for r in rows]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_product_by_id(product_id: str) -> dict | None:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", name_en AS "nameEn", description_ar AS "descriptionAr", category_name AS category, price, old_price AS "oldPrice", rating, review_count AS "reviewCount", image_url AS "imageUrl", bazaar_name AS "bazaarName", material, sizes FROM products WHERE id = %s', (product_id,))
            row = cur.fetchone()
            if row:
                res = dict(row)
                if res.get("sizes") and isinstance(res["sizes"], str):
                    try:
                        res["sizes"] = json.loads(res["sizes"])
                    except Exception:
                        res["sizes"] = [res["sizes"]]
                return res
        return None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_featured_products(limit: int = 5) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", category_name AS category, price, image_url AS "imageUrl", bazaar_name AS "bazaarName", rating FROM products ORDER BY rating DESC NULLS LAST LIMIT %s', (limit,))
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_all_products() -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", category_name AS category, price, old_price AS "oldPrice", rating, review_count AS "reviewCount", is_active AS "isActive", is_featured AS "isFeatured" FROM products')
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_bazaar_products(bazaar_id: str, limit: int = 20) -> list[dict]:
    """Get products for a specific bazaar — used by owner_ai.py."""
    return await search_products(bazaar_id=bazaar_id, limit=limit)


# ============================================================
# Artifact Queries (Aurora PostgreSQL)
# ============================================================

async def get_artifact_by_id(artifact_id: str) -> dict | None:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", description_ar AS "descriptionAr", era, location, image_url AS "imageUrl" FROM artifacts WHERE id = %s', (artifact_id,))
            row = cur.fetchone()
            return dict(row) if row else None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def search_artifacts(query: str = None, era: str = None, limit: int = 10) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            sql = 'SELECT id, name_ar AS "nameAr", description_ar AS "descriptionAr", era FROM artifacts WHERE 1=1'
            params = []
            if era:
                sql += " AND era ILIKE %s"
                params.append(f"%{era}%")
            if query:
                sql += " AND (name_ar ILIKE %s OR description_ar ILIKE %s)"
                q = f"%{query}%"
                params.extend([q, q])
            sql += " LIMIT %s"
            params.append(limit)
            cur.execute(sql, params)
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# Bazaar Queries (Aurora PostgreSQL)
# ============================================================

async def get_bazaar_by_id(bazaar_id: str) -> dict | None:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", description_ar AS "descriptionAr", address, working_hours AS "workingHours", phone, rating, review_count AS "reviewCount", is_open AS "isOpen", latitude, longitude FROM bazaars WHERE id = %s', (bazaar_id,))
            row = cur.fetchone()
            return dict(row) if row else None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_nearby_bazaars(lat: float, lng: float, radius_km: float = 50) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", address, is_open AS "isOpen", working_hours AS "workingHours", latitude, longitude FROM bazaars')
            rows = cur.fetchall()
            results = []
            for b in rows:
                b_lat = float(b.get("latitude") or 0)
                b_lng = float(b.get("longitude") or 0)
                if b_lat == 0 and b_lng == 0:
                    continue
                # Haversine distance
                dlat = math.radians(b_lat - lat)
                dlng = math.radians(b_lng - lng)
                a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat)) * math.cos(math.radians(b_lat)) * math.sin(dlng / 2) ** 2
                c = 2 * math.asin(math.sqrt(a))
                dist = 6371 * c
                if dist <= radius_km:
                    b_dict = dict(b)
                    b_dict["distance_km"] = round(dist, 1)
                    results.append(b_dict)
            return sorted(results, key=lambda x: x["distance_km"])

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_bazaar_application(bazaar_id: str) -> dict | None:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM bazaar_applications WHERE id = %s", (bazaar_id,))
            row = cur.fetchone()
            return dict(row) if row else None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_all_bazaars() -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT id, name_ar AS "nameAr", name_en AS "nameEn", address, is_open AS "isOpen", is_approved AS "isApproved" FROM bazaars')
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# Analytics & Orders Queries (Aurora PostgreSQL)
# ============================================================

async def get_bazaar_orders(bazaar_id: str, days: int) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            cur.execute("SELECT * FROM orders WHERE bazaar_id = %s AND created_at >= %s", (bazaar_id, cutoff))
            orders = [dict(r) for r in cur.fetchall()]
            for o in orders:
                cur.execute("SELECT * FROM order_items WHERE order_id = %s", (o["id"],))
                o["items"] = [dict(r) for r in cur.fetchall()]
            return orders

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_all_orders(days: int) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            cur.execute("SELECT * FROM orders WHERE created_at >= %s", (cutoff,))
            orders = [dict(r) for r in cur.fetchall()]
            for o in orders:
                cur.execute("SELECT * FROM order_items WHERE order_id = %s", (o["id"],))
                o["items"] = [dict(r) for r in cur.fetchall()]
            return orders

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_bazaar_reviews(bazaar_id: str) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM reviews WHERE bazaar_id = %s", (bazaar_id,))
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_bazaar_messages(bazaar_id: str, limit: int) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM messages WHERE bazaar_id = %s ORDER BY created_at DESC LIMIT %s", (bazaar_id, limit))
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# Cart Queries (DynamoDB)
# ============================================================

async def get_cart_items(user_id: str) -> list[dict]:
    if not user_id or user_id == "default":
        return []

    def _query():
        table = get_dynamo_table("AiCarts")
        res = table.get_item(Key={"UserId": user_id})
        item = res.get("Item", {})
        items_str = item.get("Items", "[]")
        return json.loads(items_str)

    try:
        return await asyncio.to_thread(_query)
    except Exception:
        return []


async def add_cart_item(user_id: str, item: dict):
    if not user_id or user_id == "default":
        return

    def _query():
        table = get_dynamo_table("AiCarts")
        # Get current items synchronously
        res = table.get_item(Key={"UserId": user_id})
        existing = res.get("Item", {})
        items_str = existing.get("Items", "[]")
        items = json.loads(items_str)

        # Check if exists
        doc_id = f"{item['productId']}_{item.get('selectedSize', '')}"
        found = False
        for it in items:
            it_id = f"{it['productId']}_{it.get('selectedSize', '')}"
            if it_id == doc_id:
                it["quantity"] = it.get("quantity", 1) + item.get("quantity", 1)
                found = True
                break
        if not found:
            items.append(item)

        table.put_item(Item={"UserId": user_id, "Items": json.dumps(items)})

    try:
        await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Dynamo Cart Add Error: {e}")


async def remove_cart_item(user_id: str, item_index: int):
    def _query():
        table = get_dynamo_table("AiCarts")
        res = table.get_item(Key={"UserId": user_id})
        existing = res.get("Item", {})
        items_str = existing.get("Items", "[]")
        items = json.loads(items_str)
        if 0 <= item_index < len(items):
            items.pop(item_index)
            table.put_item(Item={"UserId": user_id, "Items": json.dumps(items)})

    try:
        await asyncio.to_thread(_query)
    except Exception:
        pass


async def clear_cart(user_id: str):
    def _query():
        table = get_dynamo_table("AiCarts")
        table.delete_item(Key={"UserId": user_id})

    try:
        await asyncio.to_thread(_query)
    except Exception:
        pass


# ============================================================
# Coupon Queries (DynamoDB)
# ============================================================

async def get_available_coupons() -> list[dict]:
    def _query():
        table = get_dynamo_table("AiCoupons")
        res = table.scan()
        items = res.get("Items", [])
        return [i for i in items if i.get("isActive")]

    try:
        return await asyncio.to_thread(_query)
    except Exception:
        return []


async def validate_coupon(code: str) -> dict | None:
    def _query():
        table = get_dynamo_table("AiCoupons")
        res = table.get_item(Key={"Code": code})
        item = res.get("Item", {})
        if item and item.get("isActive"):
            return item
        return None

    try:
        return await asyncio.to_thread(_query)
    except Exception:
        return None


# ============================================================
# User Memory (DynamoDB)
# ============================================================

async def save_conversation_summary(user_id: str, summary: str):
    def _query():
        table = get_dynamo_table("AiEpisodes")
        table.put_item(Item={
            "UserId": user_id,
            "Timestamp": datetime.utcnow().isoformat(),
            "Summary": summary
        })

    try:
        await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Dynamo Episode save error: {e}")


async def get_conversation_summaries(user_id: str, limit: int = 5) -> list[str]:
    def _query():
        table = get_dynamo_table("AiEpisodes")
        from boto3.dynamodb.conditions import Key
        res = table.query(
            KeyConditionExpression=Key('UserId').eq(user_id),
            ScanIndexForward=False,
            Limit=limit
        )
        return [i.get("Summary", "") for i in res.get("Items", [])]

    try:
        return await asyncio.to_thread(_query)
    except Exception:
        return []


async def get_user_memory(user_id: str) -> dict:
    from memory.aws_memory import get_preferences
    prefs = get_preferences(user_id)
    return {
        "preferences": prefs,
        "topics_discussed": [],
        "conversation_count": 0
    }
