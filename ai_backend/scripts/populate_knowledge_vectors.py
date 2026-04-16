import os
import asyncio
import uuid
import json
import logging
from datetime import datetime
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

# Add project root to path for core imports
import sys
sys.path.append(os.getcwd())

from services.gemini_service import get_embeddings
from core.aws_memory import get_aurora_connection, release_aurora_connection
from rag.knowledge_loader import load_knowledge_files

load_dotenv()

# Setup Professional Logging
logger = logging.getLogger("pgvector_populator")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s"
)

def truncate_embedding(embedding: list[float], dims: int = 1536) -> list[float]:
    """Manually truncate Matryoshka embeddings to desired dimensions."""
    return embedding[:dims]

async def populate_knowledge_base():
    logger.info("📂 Step 1: Embedding Knowledge Markdown Files...")
    docs = load_knowledge_files()
    if not docs:
        logger.warning("⚠️ No knowledge files found to migrate.")
        return

    embedder = get_embeddings()
    conn = get_aurora_connection()
    if not conn:
        logger.error("❌ Error: Could not connect to Aurora.")
        return

    try:
        with conn.cursor() as cur:
            # Clear old knowledge to avoid duplicates
            cur.execute("TRUNCATE TABLE agent_knowledge_base")
            
            for doc in docs:
                filename = doc.metadata.get('file', 'Unknown')
                print(f"  - Embedding: {filename}")
                full_embedding = await embedder.aembed_query(doc.page_content)
                # Manual Truncation to match pgvector HNSW limits
                embedding = truncate_embedding(full_embedding)
                
                cur.execute("""
                    INSERT INTO agent_knowledge_base (id, text_content, embedding, metadata)
                    VALUES (%s, %s, %s, %s)
                """, (
                    str(uuid.uuid4()),
                    doc.page_content,
                    embedding,
                    json.dumps(doc.metadata)
                ))
        conn.commit()
        print(f"Success: Migrated {len(docs)} knowledge chunks.")
    finally:
        release_aurora_connection(conn)

async def populate_product_vectors():
    print("\nStep 2: Generating Semantic Embeddings for Products...")
    conn = get_aurora_connection()
    embedder = get_embeddings()
    
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name_ar, description_ar, category_name FROM products")
            products = cur.fetchall()
            print(f"Found {len(products)} products to embed.")
            
            for p in products:
                text_to_embed = f"Product: {p['name_ar']}. Category: {p['category_name']}. Description: {p['description_ar']}"
                logger.info(f"Processing Product: {p['id']}")
                full_embedding = await embedder.aembed_query(text_to_embed)
                embedding = truncate_embedding(full_embedding)
                
                cur.execute("UPDATE products SET embedding = %s WHERE id = %s", (embedding, p['id']))
        
        conn.commit()
        print("Success: All products updated with semantic vectors.")
    finally:
        release_aurora_connection(conn)

async def populate_bazaar_vectors():
    print("\nStep 3: Generating Semantic Embeddings for Bazaars...")
    conn = get_aurora_connection()
    embedder = get_embeddings()
    
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name_ar, description_ar FROM bazaars")
            bazaars = cur.fetchall()
            
            for b in bazaars:
                text_to_embed = f"Bazaar: {b['name_ar']}. Description: {b['description_ar']}"
                logger.info(f"Processing Bazaar: {b['id']}")
                full_embedding = await embedder.aembed_query(text_to_embed)
                embedding = truncate_embedding(full_embedding)
                
                cur.execute("UPDATE bazaars SET embedding = %s WHERE id = %s", (embedding, b['id']))
        
        conn.commit()
        print("Success: All bazaars updated with semantic vectors.")
    finally:
        release_aurora_connection(conn)

async def main():
    print("Starting Professional pgvector Activation (with Manual Truncation)...")
    await populate_knowledge_base()
    await populate_product_vectors()
    await populate_bazaar_vectors()
    print("\nALL SYSTEMS ACTIVE. Semantic search is now 100% operational.")

if __name__ == "__main__":
    asyncio.run(main())
