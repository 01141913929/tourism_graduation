"""
☁️ Core AWS Memory — Aurora connection pool + DynamoDB helpers.
Shared by all microservices for database access.
✅ Consolidated Professional Architecture (1536-dim vectors + HNSW)
"""
import os
import json
import logging
import psycopg2
import psycopg2.pool
import boto3
import threading
from datetime import datetime
from dotenv import load_dotenv
from psycopg2.extras import RealDictCursor

# Load environment variables from .env file
load_dotenv()

logger = logging.getLogger(__name__)

# ============================================================
# AWS Environment Variables
# ============================================================
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_WS_TABLE = os.getenv("WS_CONNECTIONS_TABLE", "AiConnections")
DYNAMODB_SESSIONS_TABLE = os.getenv("SESSIONS_TABLE", "AiSessions")
DYNAMODB_PREFS_TABLE = os.getenv("PREFERENCES_TABLE", "UserPreferences")
AURORA_HOST = os.getenv("AURORA_HOST", "localhost")
AURORA_USER = os.getenv("AURORA_USER", "postgres")
AURORA_PASS = os.getenv("AURORA_PASS", "password")
AURORA_DB = os.getenv("AURORA_DB", "tourism_ai")

# ============================================================
# Singletons & Locks
# ============================================================
_dynamodb_resource = None
_aurora_pool: psycopg2.pool.ThreadedConnectionPool | None = None
_pool_lock = threading.Lock()
_dynamo_lock = threading.Lock()

def _get_dynamodb():
    global _dynamodb_resource
    if _dynamodb_resource is None:
        with _dynamo_lock:
            if _dynamodb_resource is None:
                _dynamodb_resource = boto3.resource('dynamodb', region_name=AWS_REGION)
    return _dynamodb_resource

_dynamo_table_cache = {}

def get_dynamo_table(table_name: str):
    if table_name not in _dynamo_table_cache:
        dynamodb = _get_dynamodb()
        _dynamo_table_cache[table_name] = dynamodb.Table(table_name)
    return _dynamo_table_cache[table_name]

# ============================================================
# DynamoDB Helpers
# ============================================================
def save_session_data(session_id: str, data: dict):
    try:
        table = get_dynamo_table(DYNAMODB_SESSIONS_TABLE)
        table.put_item(Item={
            'SessionId': session_id,
            'Data': json.dumps(data, ensure_ascii=False),
            'UpdatedAt': datetime.now().isoformat()
        })
    except Exception as e:
        logger.warning(f"DynamoDB Save Error: {e}")

def get_session_data(session_id: str) -> dict | None:
    try:
        table = get_dynamo_table(DYNAMODB_SESSIONS_TABLE)
        res = table.get_item(Key={'SessionId': session_id})
        item = res.get('Item')
        if item and 'Data' in item:
            return json.loads(item['Data'])
    except Exception as e:
        logger.warning(f"DynamoDB Get Error: {e}")
    return None

def get_user_memory(user_id: str) -> dict:
    try:
        table = get_dynamo_table(DYNAMODB_PREFS_TABLE)
        res = table.get_item(Key={'UserId': user_id})
        item = res.get('Item')
        if item and 'Preferences' in item:
            return json.loads(item['Preferences'])
    except Exception:
        pass
    return {}

def save_user_memory(user_id: str, memory: dict):
    try:
        table = get_dynamo_table(DYNAMODB_PREFS_TABLE)
        table.put_item(Item={
            'UserId': user_id,
            'Preferences': json.dumps(memory, ensure_ascii=False)
        })
    except Exception as e:
        logger.warning(f"Failed to save user memory: {e}")

# ============================================================
# WebSocket Connection Management (DynamoDB)
# ============================================================
def save_connection(connection_id: str, user_id: str = "anonymous"):
    try:
        table = get_dynamo_table(DYNAMODB_WS_TABLE)
        table.put_item(Item={
            'ConnectionId': connection_id,
            'UserId': user_id,
            'Timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.warning(f"Failed to save connection: {e}")

def remove_connection(connection_id: str):
    try:
        table = get_dynamo_table(DYNAMODB_WS_TABLE)
        table.delete_item(Key={'ConnectionId': connection_id})
    except Exception as e:
        logger.warning(f"Failed to remove connection: {e}")

# ============================================================
# Aurora Connection Pool
# ============================================================
def _get_public_ip(hostname: str) -> str:
    if os.getenv("AWS_LAMBDA_FUNCTION_NAME") or hostname in ["localhost", "127.0.0.1", "db"]:
        return hostname
    import socket
    try:
        return socket.gethostbyname(hostname)
    except:
        return hostname

def _get_aurora_pool():
    global _aurora_pool
    if _aurora_pool is None:
        with _pool_lock:
            if _aurora_pool is None:
                try:
                    host = _get_public_ip(AURORA_HOST)
                    _aurora_pool = psycopg2.pool.ThreadedConnectionPool(
                        minconn=1, maxconn=20,
                        host=host, database=AURORA_DB,
                        user=AURORA_USER, password=AURORA_PASS,
                        sslmode='require', connect_timeout=10
                    )
                    logger.info("✅ Aurora Connection Pool Initialized")
                except Exception as e:
                    logger.error(f"❌ Failed to init Aurora pool: {e}")
    return _aurora_pool

def get_aurora_connection():
    pool = _get_aurora_pool()
    return pool.getconn() if pool else None

def release_aurora_connection(conn):
    if conn and _aurora_pool: _aurora_pool.putconn(conn)

# ============================================================
# 🏛️ Unified Professional Schema Initialization
# ============================================================
def initialize_db_schema():
    """Consolidated Aurora schema initialization (1536-dim).
    Professional production-ready implementation with robust error handling.
    """
    logger.info("🏛️ Starting Aurora Schema Initialization...")
    conn = get_aurora_connection()
    if not conn:
        logger.error("❌ Critical: Could not acquire Aurora connection for schema init.")
        return
    try:
        with conn.cursor() as cur:
            cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
            
            # 1. Knowledge Base
            cur.execute('''
                CREATE TABLE IF NOT EXISTS agent_knowledge_base (
                    id UUID PRIMARY KEY,
                    text_content TEXT NOT NULL,
                    embedding vector(1536),
                    metadata JSONB,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ''')
            cur.execute("ALTER TABLE agent_knowledge_base ADD COLUMN IF NOT EXISTS embedding vector(1536);")
            cur.execute("ALTER TABLE agent_knowledge_base ALTER COLUMN embedding TYPE vector(1536);")

            # 2. Bazaars
            cur.execute('''
                CREATE TABLE IF NOT EXISTS bazaars (
                    id VARCHAR(255) PRIMARY KEY,
                    name_ar VARCHAR(255),
                    name_en VARCHAR(255),
                    description_ar TEXT,
                    address TEXT,
                    phone VARCHAR(50),
                    rating NUMERIC(3,2),
                    is_open BOOLEAN DEFAULT TRUE,
                    latitude NUMERIC(10,8),
                    longitude NUMERIC(11,8),
                    embedding vector(1536),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ''')
            cur.execute("ALTER TABLE bazaars ADD COLUMN IF NOT EXISTS embedding vector(1536);")
            cur.execute("ALTER TABLE bazaars ALTER COLUMN embedding TYPE vector(1536);")

            # 3. Products
            cur.execute('''
                CREATE TABLE IF NOT EXISTS products (
                    id VARCHAR(255) PRIMARY KEY,
                    name_ar VARCHAR(255),
                    name_en VARCHAR(255),
                    description_ar TEXT,
                    category_name VARCHAR(255),
                    price NUMERIC(10,2),
                    image_url TEXT,
                    bazaar_id VARCHAR(255),
                    bazaar_name VARCHAR(255),
                    embedding vector(1536),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ''')
            cur.execute("ALTER TABLE products ADD COLUMN IF NOT EXISTS embedding vector(1536);")
            cur.execute("ALTER TABLE products ALTER COLUMN embedding TYPE vector(1536);")

            # 4. HNSW Indexes
            for table, idx in [('products', 'idx_products_vector'), 
                               ('bazaars', 'idx_bazaars_vector'),
                               ('agent_knowledge_base', 'idx_knowledge_vector')]:
                cur.execute(f"SELECT 1 FROM pg_indexes WHERE indexname = '{idx}';")
                if not cur.fetchone():
                    logger.info(f"Creating HNSW index for {table}...")
                    cur.execute(f"CREATE INDEX {idx} ON {table} USING hnsw (embedding vector_cosine_ops);")
            
            # 5. Core Business Tables
            cur.execute("CREATE TABLE IF NOT EXISTS orders (id VARCHAR(255) PRIMARY KEY, user_id VARCHAR(255), total_amount NUMERIC(10,2), status VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);")
            cur.execute("CREATE TABLE IF NOT EXISTS order_items (id SERIAL PRIMARY KEY, order_id VARCHAR(255) REFERENCES orders(id), product_id VARCHAR(255), quantity INTEGER, price NUMERIC(10,2));")
            cur.execute("CREATE TABLE IF NOT EXISTS reviews (id VARCHAR(255) PRIMARY KEY, product_id VARCHAR(255), rating INTEGER, comment TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);")
            cur.execute("CREATE TABLE IF NOT EXISTS users (id VARCHAR(255) PRIMARY KEY, name VARCHAR(255), email VARCHAR(255), role VARCHAR(50) DEFAULT 'USER', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);")

        conn.commit()
        logger.info("✅ Consolidated Aurora Schema successfully initialized (1536 dims).")
    except Exception as e:
        logger.error(f"❌ Schema Init Error: {e}")
        if conn: conn.rollback()
    finally:
        release_aurora_connection(conn)

# ============================================================
# 📊 Semantic Search Helpers
# ============================================================
def search_knowledge_pgvector(query_embedding: list[float], limit: int = 5):
    conn = get_aurora_connection()
    if not conn: return []
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute('''
                SELECT id, text_content, metadata, 1 - (embedding <=> %s::vector) AS similarity
                FROM agent_knowledge_base ORDER BY embedding <=> %s::vector LIMIT %s
            ''', (query_embedding, query_embedding, limit))
            res = cur.fetchall()
            return [{"id": str(r["id"]), "content": r["text_content"], "source": r.get("metadata",{}).get("source","KB"), "score": float(r["similarity"])} for r in res]
    except Exception as e:
        logger.error(f"Vector Search Error: {e}")
        return []
    finally:
        release_aurora_connection(conn)

# Compatibility Aliases
_initialize_db_schema = initialize_db_schema
init_aurora_schema = initialize_db_schema
get_user_preferences = get_user_memory
get_preferences = get_user_memory
save_user_preferences = save_user_memory
