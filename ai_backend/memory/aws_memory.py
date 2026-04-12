"""
☁️ AWS Memory Adapter
واجهة ربط الذاكرة بقواعد بيانات AWS (Aurora PostgreSQL V2 & DynamoDB)
✅ Production-ready مع Connection Pooling + Singleton DynamoDB + Proper async support
"""
import os
import json
import logging
import psycopg2
import psycopg2.pool
import boto3
from psycopg2.extras import RealDictCursor

logger = logging.getLogger(__name__)

# ============================================================
# AWS Environment Variables
# ============================================================
AWS_REGION = os.getenv("AWS_REGION", "eu-west-1")
DYNAMODB_WS_TABLE = os.getenv("WS_CONNECTIONS_TABLE", "AiConnections")
DYNAMODB_SESSIONS_TABLE = os.getenv("SESSIONS_TABLE", "AiSessions")
DYNAMODB_PREFS_TABLE = os.getenv("PREFERENCES_TABLE", "UserPreferences")
AURORA_HOST = os.getenv("AURORA_HOST", "localhost")
AURORA_USER = os.getenv("AURORA_USER", "postgres")
AURORA_PASS = os.getenv("AURORA_PASS", "password")
AURORA_DB = os.getenv("AURORA_DB", "tourism_ai")

# ============================================================
# DynamoDB Singleton Resource (MED-06 Fix)
# ============================================================
_dynamodb_resource = None


def _get_dynamodb():
    """Get cached DynamoDB resource — singleton pattern."""
    global _dynamodb_resource
    if _dynamodb_resource is None:
        _dynamodb_resource = boto3.resource('dynamodb', region_name=AWS_REGION)
        logger.info("✅ DynamoDB resource initialized (singleton)")
    return _dynamodb_resource


_dynamo_table_cache: dict[str, object] = {}


def get_dynamo_table(table_name: str):
    """Get DynamoDB table — cached to avoid repeated lookups."""
    if table_name not in _dynamo_table_cache:
        dynamodb = _get_dynamodb()
        _dynamo_table_cache[table_name] = dynamodb.Table(table_name)
    return _dynamo_table_cache[table_name]


# ============================================================
# DynamoDB Connection Management (WebSockets)
# ============================================================
def save_connection(connection_id: str, session_id: str, user_id: str = ""):
    """حفظ اتصال المستخدم عند دخول الـ WebSocket"""
    try:
        table = get_dynamo_table(DYNAMODB_WS_TABLE)
        table.put_item(
            Item={
                'ConnectionId': connection_id,
                'SessionId': session_id,
                'UserId': user_id,
            }
        )
    except Exception as e:
        logger.warning(f"DynamoDB Save Error: {e}")


def get_connection(session_id: str) -> str | None:
    """البحث عن connection_id نشط باستخدام session_id"""
    try:
        table = get_dynamo_table(DYNAMODB_WS_TABLE)
        response = table.scan(
            FilterExpression="SessionId = :sid",
            ExpressionAttributeValues={":sid": session_id}
        )
        items = response.get('Items', [])
        if items:
            return items[0].get('ConnectionId')
    except Exception as e:
        logger.warning(f"DynamoDB Get Error: {e}")
    return None


def remove_connection(connection_id: str):
    """إزالة الاتصال عند الخروج"""
    try:
        table = get_dynamo_table(DYNAMODB_WS_TABLE)
        table.delete_item(Key={'ConnectionId': connection_id})
    except Exception as e:
        logger.warning(f"DynamoDB Remove Error: {e}")


# ============================================================
# DynamoDB Persistence (Working & Semantic Memory)
# ============================================================

def get_session_data(session_id: str) -> dict | None:
    """استرجاع بيانات الجلسة (Working Memory)"""
    try:
        table = get_dynamo_table(DYNAMODB_SESSIONS_TABLE)
        res = table.get_item(Key={'SessionId': session_id})
        item = res.get('Item')
        if item and 'Data' in item:
            return json.loads(item['Data'])
    except Exception as e:
        logger.warning(f"Failed to get session {session_id}: {e}")
    return None


def save_session_data(session_id: str, data: dict):
    """حفظ الجلسة (Working Memory)"""
    try:
        table = get_dynamo_table(DYNAMODB_SESSIONS_TABLE)
        table.put_item(Item={
            'SessionId': session_id,
            'Data': json.dumps(data, ensure_ascii=False)
        })
    except Exception as e:
        logger.warning(f"Failed to save session {session_id}: {e}")


def get_user_preferences(user_id: str) -> dict | None:
    """استرجاع التفضيلات الطويلة الأمد (Semantic Memory)"""
    try:
        table = get_dynamo_table(DYNAMODB_PREFS_TABLE)
        res = table.get_item(Key={'UserId': user_id})
        item = res.get('Item')
        if item and 'Preferences' in item:
            return json.loads(item['Preferences'])
    except Exception as e:
        logger.warning(f"Failed to get preferences {user_id}: {e}")
    return None


def save_user_preferences(user_id: str, prefs: dict):
    """حفظ التفضيلات الطويلة الأمد"""
    try:
        table = get_dynamo_table(DYNAMODB_PREFS_TABLE)
        table.put_item(Item={
            'UserId': user_id,
            'Preferences': json.dumps(prefs, ensure_ascii=False)
        })
    except Exception as e:
        logger.warning(f"Failed to save preferences {user_id}: {e}")


def get_preferences(user_id: str) -> dict:
    """Alias for get_user_preferences — returns empty dict on failure."""
    return get_user_preferences(user_id) or {}


# ============================================================
# Aurora Serverless V2 — Connection Pool (BUG-03 + MED-04 Fix)
# ============================================================

_aurora_pool: psycopg2.pool.ThreadedConnectionPool | None = None


def _get_aurora_pool() -> psycopg2.pool.ThreadedConnectionPool | None:
    """Get or create the Aurora connection pool."""
    global _aurora_pool
    if _aurora_pool is None:
        try:
            _aurora_pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=1,
                maxconn=10,
                host=AURORA_HOST,
                database=AURORA_DB,
                user=AURORA_USER,
                password=AURORA_PASS,
            )
            logger.info("✅ Aurora connection pool initialized (1-10 connections)")
        except Exception as e:
            logger.error(f"Failed to create Aurora connection pool: {e}")
            return None
    return _aurora_pool


def get_aurora_connection():
    """Get a connection from the pool. Returns None on failure.

    ⚠️ IMPORTANT: This returns a raw connection (NOT a context manager).
    Callers MUST return the connection via `release_aurora_connection()`.
    """
    pool = _get_aurora_pool()
    if pool is None:
        return None
    try:
        conn = pool.getconn()
        conn.autocommit = True
        return conn
    except Exception as e:
        logger.error(f"Failed to get Aurora connection: {e}")
        return None


def release_aurora_connection(conn):
    """Return a connection back to the pool."""
    if conn is None:
        return
    pool = _get_aurora_pool()
    if pool:
        try:
            pool.putconn(conn)
        except Exception as e:
            logger.warning(f"Failed to release Aurora connection: {e}")


# ============================================================
# pgvector Search Functions
# ============================================================

def search_products_pgvector(query_embedding: list[float], limit: int = 5):
    """
    استرجاع المنتجات من Aurora باستخدام فهرس HNSW لـ pgvector.
    """
    conn = get_aurora_connection()
    if not conn:
        return []
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute('''
                SELECT id, name_ar, price, category, bazaar_name, image_url,
                       1 - (embedding <=> %s::vector) AS similarity
                FROM products
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            ''', (query_embedding, query_embedding, limit))

            results = cursor.fetchall()

            products = []
            for row in results:
                products.append({
                    "product_id": row["id"],
                    "name_ar": row["name_ar"],
                    "price": float(row["price"]),
                    "category": row["category"],
                    "bazaar_name": row["bazaar_name"],
                    "image_url": row["image_url"],
                    "score": float(row["similarity"])
                })
            return products
    except Exception as e:
        logger.error(f"pgvector product search error: {e}")
        return []
    finally:
        release_aurora_connection(conn)


def search_knowledge_pgvector(query_embedding: list[float], limit: int = 5):
    """استرجاع معلومات RAG من جدول المعرفة باستخدام pgvector."""
    conn = get_aurora_connection()
    if not conn:
        return []
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute('''
                SELECT id, content, source,
                       1 - (embedding <=> %s::vector) AS similarity
                FROM knowledge_chunks
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            ''', (query_embedding, query_embedding, limit))

            results = cursor.fetchall()
            docs = []
            for row in results:
                docs.append({
                    "id": row["id"],
                    "content": row["content"],
                    "source": row["source"],
                    "score": float(row["similarity"])
                })
            return docs
    except Exception as e:
        logger.error(f"pgvector knowledge search error: {e}")
        return []
    finally:
        release_aurora_connection(conn)


def init_aurora_schema():
    """إعداد الجداول والفهارس في Aurora. (MED-05 Fix: 768 dims for Gemini)"""
    conn = get_aurora_connection()
    if not conn:
        logger.error("Cannot init schema — no Aurora connection.")
        return
    try:
        conn.autocommit = False
        with conn.cursor() as cursor:
            # 1. تفعيل مكتبة pgvector
            cursor.execute("CREATE EXTENSION IF NOT EXISTS vector;")

            # 2. إنشاء جدول المنتجات (768 dims for Gemini text-embedding-004)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id TEXT PRIMARY KEY,
                    name_ar TEXT,
                    name_en TEXT,
                    description_ar TEXT,
                    category_name TEXT,
                    price NUMERIC,
                    old_price NUMERIC,
                    rating NUMERIC,
                    review_count INTEGER DEFAULT 0,
                    image_url TEXT,
                    bazaar_name TEXT,
                    bazaar_id TEXT,
                    material TEXT,
                    sizes TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    is_featured BOOLEAN DEFAULT FALSE,
                    embedding vector(768)
                );
            """)

            # 3. إنشاء جدول المعرفة RAG (768 dims for Gemini)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_chunks (
                    id TEXT PRIMARY KEY,
                    content TEXT,
                    source TEXT,
                    embedding vector(768)
                );
            """)

            # 4. إنشاء جدول الآثار (Artifacts)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS artifacts (
                    id TEXT PRIMARY KEY,
                    name_ar TEXT,
                    name_en TEXT,
                    description_ar TEXT,
                    era TEXT,
                    location TEXT,
                    image_url TEXT
                );
            """)

            # 5. إنشاء جدول البازارات (Bazaars)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS bazaars (
                    id TEXT PRIMARY KEY,
                    name_ar TEXT,
                    name_en TEXT,
                    description_ar TEXT,
                    address TEXT,
                    working_hours TEXT,
                    phone TEXT,
                    rating NUMERIC,
                    review_count INTEGER,
                    is_open BOOLEAN,
                    is_approved BOOLEAN DEFAULT TRUE,
                    latitude NUMERIC,
                    longitude NUMERIC
                );
            """)

            # 6. طلبات الانضمام للبازارات
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS bazaar_applications (
                    id TEXT PRIMARY KEY,
                    name_ar TEXT,
                    description_ar TEXT,
                    address TEXT,
                    phone TEXT,
                    owner_name TEXT,
                    email TEXT,
                    status TEXT DEFAULT 'pending'
                );
            """)

            # 7. جدول الطلبات والمبيعات (Orders)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS orders (
                    id TEXT PRIMARY KEY,
                    user_id TEXT,
                    bazaar_id TEXT,
                    total NUMERIC,
                    subtotal NUMERIC,
                    status TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)

            # 8. تفاصيل الطلبات (Order Items)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS order_items (
                    id SERIAL PRIMARY KEY,
                    order_id TEXT REFERENCES orders(id),
                    product_id TEXT,
                    product_name TEXT,
                    category TEXT,
                    quantity INTEGER,
                    price NUMERIC,
                    total_price NUMERIC
                );
            """)

            # 9. التقييمات والمراجعات (Reviews)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS reviews (
                    id TEXT PRIMARY KEY,
                    bazaar_id TEXT,
                    product_id TEXT,
                    user_id TEXT,
                    rating NUMERIC,
                    comment TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)

            # 10. الرسائل (Messages)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id TEXT PRIMARY KEY,
                    bazaar_id TEXT,
                    user_id TEXT,
                    customer_name TEXT,
                    content TEXT,
                    direction TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)

            # 11. HNSW indexes for fast vector search
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS products_embedding_idx
                ON products USING hnsw (embedding vector_cosine_ops)
                WITH (m = 16, ef_construction = 64);
            """)

            cursor.execute("""
                CREATE INDEX IF NOT EXISTS knowledge_embedding_idx
                ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)
                WITH (m = 16, ef_construction = 64);
            """)
        conn.commit()
        logger.info("✅ Aurora Schema initialized with pgvector & HNSW indexes (768-dim Gemini)")
    except Exception as e:
        logger.error(f"Aurora schema init error: {e}")
        conn.rollback()
    finally:
        release_aurora_connection(conn)
