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


async def search_products_vector(query_embedding: list[float], limit: int = 5) -> list[dict]:
    """Semantic search for products using pgvector cosine distance."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('''
                SELECT id, name_ar AS "nameAr", name_en AS "nameEn", 
                       description_ar AS "descriptionAr", category_name AS category, 
                       price, image_url AS "imageUrl", bazaar_name AS "bazaarName",
                       (embedding <=> %s::vector) as distance
                FROM products
                ORDER BY distance ASC
                LIMIT %s
            ''', (query_embedding, limit))
            return [dict(r) for r in cur.fetchall()]

    return await asyncio.to_thread(_execute_aurora_query, _query)


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
            cur.execute('SELECT id, name_ar AS "nameAr", name_en AS "nameEn", description_ar AS "descriptionAr", category_name AS category, price, old_price AS "oldPrice", rating, review_count AS "reviewCount", image_url AS "imageUrl", bazaar_name AS "bazaarName", bazaar_id AS "bazaarId", is_active AS "isActive", is_featured AS "isFeatured" FROM products')
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


async def search_bazaars_vector(query_embedding: list[float], limit: int = 3) -> list[dict]:
    """Semantic search for bazaars using pgvector cosine distance."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('''
                SELECT id, name_ar AS "nameAr", description_ar AS "descriptionAr", 
                       address, is_open AS "isOpen", (embedding <=> %s::vector) as distance
                FROM bazaars
                ORDER BY distance ASC
                LIMIT %s
            ''', (query_embedding, limit))
            return [dict(r) for r in cur.fetchall()]

    return await asyncio.to_thread(_execute_aurora_query, _query)


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


# ============================================================
# Professional Analytics (Optimized SQL Aggregations)
# ============================================================

async def get_platform_metrics_sql(days: int = 30) -> dict:
    """Get core platform metrics directly via SQL SUM/COUNT."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            
            # 1. Revenue & Orders & Customers
            cur.execute("""
                SELECT 
                    COUNT(id) as total_orders,
                    COALESCE(SUM(total_amount), 0) as total_revenue,
                    COUNT(DISTINCT bazaar_id) as total_active_bazaars_in_orders,
                    COUNT(DISTINCT user_id) as total_customers,
                    COUNT(id) FILTER (WHERE status = 'delivered') as delivered_orders,
                    COUNT(id) FILTER (WHERE status = 'cancelled') as cancelled_orders
                FROM orders 
                WHERE created_at >= %s
            """, (cutoff,))
            order_metrics = dict(cur.fetchone())

            # 2. Total Bazaars & Products
            cur.execute("SELECT COUNT(*) as total_bazaars, COUNT(*) FILTER (WHERE is_approved=true) as approved_bazaars FROM bazaars")
            b_counts = cur.fetchone()
            bazaar_count = b_counts["total_bazaars"]
            approved_bazaars = b_counts["approved_bazaars"]

            cur.execute("SELECT COUNT(*) as total_products FROM products WHERE is_active = true")
            product_count = cur.fetchone()["total_products"]

            return {
                **order_metrics,
                "total_bazaars": bazaar_count,
                "active_bazaars": approved_bazaars, # The UI uses this for the 13/13 indicator
                "total_products": product_count,
                "cancellation_rate": round((order_metrics["cancelled_orders"] / order_metrics["total_orders"] * 100) if order_metrics["total_orders"] > 0 else 0, 1)
            }

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_revenue_trend_sql(days: int = 30) -> list[dict]:
    """Get daily revenue data for time-series charts."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT 
                    TO_CHAR(DATE_TRUNC('day', created_at), 'YYYY-MM-DD') as date,
                    SUM(total_amount)::FLOAT as revenue
                FROM orders
                WHERE created_at >= NOW() - %s * INTERVAL '1 day'
                GROUP BY 1
                ORDER BY 1 ASC
            """, (days,))
            return [dict(r) for r in cur.fetchall()]

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_bazaar_rankings_sql(days: int = 30, limit: int = 10) -> list[dict]:
    """Rank bazaars by revenue using SQL GROUP BY."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cutoff = datetime.utcnow() - timedelta(days=days)
            cur.execute("""
                SELECT 
                    b.id, 
                    COALESCE(b.name_ar, b.name_en, 'بازار بدون اسم') as name, 
                    SUM(o.total_amount)::FLOAT as revenue,
                    COUNT(o.id)::INTEGER as order_count
                FROM bazaars b
                JOIN orders o ON b.id = o.bazaar_id
                WHERE o.created_at >= %s AND o.status IN ('delivered', 'accepted', 'preparing')
                GROUP BY b.id, b.name_ar, b.name_en
                ORDER BY revenue DESC
                LIMIT %s
            """, (cutoff, limit))
            rows = cur.fetchall()
            return [dict(r) for r in rows]

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_category_distribution_sql() -> list[dict]:
    """Get product distribution by category."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT category_name as category, COUNT(*) as count 
                FROM products 
                GROUP BY category_name 
                ORDER BY count DESC
            """)
            return [dict(r) for r in cur.fetchall()]

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_system_health_metrics_sql() -> dict:
    """Professional health check: scans for missing data/images."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT 
                    COUNT(*) as total,
                    COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as no_image,
                    COUNT(*) FILTER (WHERE description_ar IS NULL OR description_ar = '') as no_desc
                FROM products
            """)
            p_health = dict(cur.fetchone())
            
            cur.execute("SELECT COUNT(*) as pending FROM bazaar_applications WHERE status = 'PENDING'")
            pending_apps = cur.fetchone()["pending"]

            return {
                "products_total": p_health["total"],
                "missing_images": p_health["no_image"],
                "missing_descriptions": p_health["no_desc"],
                "pending_applications": pending_apps,
                "health_score": max(0, 100 - (p_health["no_image"] * 2) - (pending_apps * 5))
            }

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_bazaar_messages(bazaar_id: str, limit: int) -> list[dict]:
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM messages WHERE bazaar_id = %s ORDER BY created_at DESC LIMIT %s", (bazaar_id, limit))
            return [dict(r) for r in cur.fetchall()]

    result = await asyncio.to_thread(_execute_aurora_query, _query)
    return result or []


# ============================================================
# Cart Queries (Firestore)
# ============================================================

from core.firebase_config import get_firestore_client
from google.cloud.firestore_v1.base_query import FieldFilter

async def get_cart_items(user_id: str) -> list[dict]:
    if not user_id or user_id == "default":
        return []

    def _query():
        db = get_firestore_client()
        if not db:
            return []
        items_ref = db.collection("carts").document(user_id).collection("items")
        docs = items_ref.stream()
        return [doc.to_dict() for doc in docs]

    try:
        return await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Firestore Cart Get Error: {e}")
        return []


async def add_cart_item(user_id: str, item: dict):
    if not user_id or user_id == "default":
        return

    def _query():
        db = get_firestore_client()
        if not db:
            return
            
        doc_id = item.get("id")
        if not doc_id:
            doc_id = f"{item.get('productId')}_{item.get('selectedSize', '')}".strip("_")
            item["id"] = doc_id

        doc_ref = db.collection("carts").document(user_id).collection("items").document(doc_id)
        doc = doc_ref.get()
        
        if doc.exists:
            existing_data = doc.to_dict()
            new_qty = existing_data.get("quantity", 1) + item.get("quantity", 1)
            doc_ref.update({"quantity": new_qty})
        else:
            doc_ref.set(item)

    try:
        await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Firestore Cart Add Error: {e}")


async def remove_cart_item(user_id: str, item_id: str):
    def _query():
        db = get_firestore_client()
        if not db:
            return
        doc_ref = db.collection("carts").document(user_id).collection("items").document(item_id)
        doc_ref.delete()

    try:
        await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Firestore Cart Remove Error: {e}")


async def clear_cart(user_id: str):
    def _query():
        db = get_firestore_client()
        if not db:
            return
        items_ref = db.collection("carts").document(user_id).collection("items")
        docs = items_ref.stream()
        for doc in docs:
            doc.reference.delete()

    try:
        await asyncio.to_thread(_query)
    except Exception as e:
        logger.error(f"Firestore Cart Clear Error: {e}")


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


# ============================================================
# Vector Knowledge Base (RAG)
# ============================================================

async def search_knowledge_base(query_embedding: list[float], limit: int = 3) -> list[dict]:
    """Semantic search in agent knowledge base using pgvector."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # We use cosine distance <=> operator in pgvector
            cur.execute("""
                SELECT text_content, metadata, (embedding <=> %s::vector) as distance
                FROM agent_knowledge_base
                ORDER BY distance ASC
                LIMIT %s
            """, (query_embedding, limit))
            return [dict(r) for r in cur.fetchall()]

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_market_prices_sql(category: str) -> dict:
    """Get market price statistics for a category directly via SQL."""
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT 
                    AVG(price)::FLOAT as average, 
                    MIN(price)::FLOAT as min, 
                    MAX(price)::FLOAT as max, 
                    COUNT(*)::INTEGER as count,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::FLOAT as median
                FROM products 
                WHERE category_name = %s AND price > 0
            """, (category,))
            return dict(cur.fetchone())

    return await asyncio.to_thread(_execute_aurora_query, _query)


async def get_user_memory(user_id: str) -> dict:
    from memory.aws_memory import get_preferences
    prefs = get_preferences(user_id)
    return {
        "preferences": prefs,
        "topics_discussed": [],
        "conversation_count": 0
    }
