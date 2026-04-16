"""
☁️ Core DB Service — Aurora PostgreSQL & DynamoDB queries.
Admin-relevant queries: products, bazaars, orders, analytics.
"""
import json
import asyncio
import logging
from decimal import Decimal
from datetime import datetime, timedelta
from psycopg2.extras import RealDictCursor
from core.aws_memory import get_aurora_connection, release_aurora_connection, get_dynamo_table

logger = logging.getLogger(__name__)


# ============================================================
# Helper: Run blocking DB call in thread pool
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


def json_serial(obj):
    """JSON serializer for objects not serializable by default json code."""
    if isinstance(obj, (datetime,)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError ("Type %s not serializable" % type(obj))


# ============================================================
# Product Queries (Aurora PostgreSQL)
# ============================================================

async def get_product_by_id(product_id: str) -> dict | None:
    """Get a single product by ID."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                'SELECT id, name_ar AS "nameAr", name_en AS "nameEn", '
                'description_ar AS "descriptionAr", description_en AS "descriptionEn", '
                'category_name AS category, price, old_price AS "oldPrice", '
                'rating, review_count AS "reviewCount", image_url AS "imageUrl", '
                'bazaar_name AS "bazaarName", bazaar_id AS "bazaarId", '
                'material, sizes '
                'FROM products WHERE id = %s', (product_id,)
            )
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


async def get_all_products() -> list[dict]:
    """Get all products (Full details — for Admin Dashboard)."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                'SELECT id, name_ar AS "nameAr", name_en AS "nameEn", '
                'description_ar AS "descriptionAr", category_name AS category, '
                'price, old_price AS "oldPrice", rating, review_count AS "reviewCount", '
                'image_url AS "imageUrl", bazaar_name AS "bazaarName", '
                'is_active AS "isActive", is_featured AS "isFeatured" '
                'FROM products'
            )
            rows = cur.fetchall()
            return [dict(r) for r in rows]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    # Ensure all numeric/decimal fields are converted for JSON safety
    if result:
        for r in result:
            if isinstance(r.get("price"), Decimal): r["price"] = float(r["price"])
            if isinstance(r.get("oldPrice"), Decimal): r["oldPrice"] = float(r["oldPrice"])
            if isinstance(r.get("rating"), Decimal): r["rating"] = float(r["rating"])
    return result or []


# ============================================================
# Bazaar Queries (Aurora PostgreSQL)
# ============================================================

async def get_bazaar_by_id(bazaar_id: str) -> dict | None:
    """Get a single bazaar by ID."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                'SELECT id, name_ar AS "nameAr", name_en AS "nameEn", '
                'description_ar AS "descriptionAr", address, '
                'working_hours AS "workingHours", phone, rating, '
                'review_count AS "reviewCount", is_open AS "isOpen", '
                'is_approved AS "isApproved", latitude, longitude '
                'FROM bazaars WHERE id = %s', (bazaar_id,)
            )
            row = cur.fetchone()
            return dict(row) if row else None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_bazaar_application(application_id: str) -> dict | None:
    """Get a bazaar application by ID."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM bazaar_applications WHERE id = %s", (application_id,))
            row = cur.fetchone()
            return dict(row) if row else None

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_all_bazaars() -> list[dict]:
    """Get all bazaars."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                'SELECT id, name_ar AS "nameAr", name_en AS "nameEn", '
                'address, is_open AS "isOpen", is_approved AS "isApproved" '
                'FROM bazaars'
            )
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# Orders & Analytics Queries (Aurora PostgreSQL)
# ============================================================

async def get_all_orders(days: int) -> list[dict]:
    """Get all orders in the last N days."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            cur.execute("""
                SELECT id, bazaar_id, total_amount AS total, status, created_at 
                FROM orders WHERE created_at >= %s
            """, (cutoff,))
            orders = [dict(r) for r in cur.fetchall()]
            for o in orders:
                cur.execute("SELECT * FROM order_items WHERE order_id = %s", (o["id"],))
                o["items"] = [dict(r) for r in cur.fetchall()]
            return orders

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_user_count() -> int:
    """Get total count of registered users."""
    def _query(conn):
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM users")
            return cur.fetchone()[0]
    return await asyncio.to_thread(_execute_aurora_query, _query) or 0


async def get_bazaar_orders(bazaar_id: str, days: int) -> list[dict]:
    """Get orders for a specific bazaar in the last N days."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            cur.execute(
                "SELECT * FROM orders WHERE bazaar_id = %s AND created_at >= %s",
                (bazaar_id, cutoff),
            )
            orders = [dict(r) for r in cur.fetchall()]
            for o in orders:
                cur.execute("SELECT * FROM order_items WHERE order_id = %s", (o["id"],))
                o["items"] = [dict(r) for r in cur.fetchall()]
            return orders

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


async def get_bazaar_reviews(bazaar_id: str) -> list[dict]:
    """Get reviews for a specific bazaar."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM reviews WHERE bazaar_id = %s", (bazaar_id,))
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# User Memory (DynamoDB)
# ============================================================

async def get_user_memory(user_id: str) -> dict:
    """Get user memory (preferences + favorites)."""
    from core.aws_memory import get_preferences
    prefs = get_preferences(user_id)
    return {
        "preferences": prefs,
        "topics_discussed": [],
        "conversation_count": 0,
    }


# ============================================================
# Market Prices (for moderation)
# ============================================================

async def get_market_prices(category: str) -> dict:
    """Get market price statistics for a given category."""
    all_p = await get_all_products()
    prices = [float(p.get("price", 0)) for p in all_p if p.get("category") == category and p.get("price")]

    if not prices:
        return {"average": 0, "min": 0, "max": 0, "count": 0}

    return {
        "average": round(sum(prices) / len(prices), 2),
        "min": min(prices),
        "max": max(prices),
        "median": sorted(prices)[len(prices) // 2],
        "count": len(prices),
    }


# ============================================================
# Category & Hall Queries (Aurora PostgreSQL)
# ============================================================

async def get_all_categories() -> list[dict]:
    """Get all categories."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT * FROM categories ORDER BY "order" ASC')
            return [dict(r) for r in cur.fetchall()]
    return await asyncio.to_thread(_execute_aurora_query, _query) or []


async def get_all_halls() -> list[dict]:
    """Get all exhibition halls."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('SELECT * FROM exhibition_halls')
            return [dict(r) for r in cur.fetchall()]
    return await asyncio.to_thread(_execute_aurora_query, _query) or []
