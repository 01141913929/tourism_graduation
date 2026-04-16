import os
import sys
import asyncio
import io
from dotenv import load_dotenv

# Ensure UTF-8 output even on Windows consoles
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Add current directory to sys.path
sys.path.append(os.getcwd())

load_dotenv()

async def test_semantic_search():
    try:
        from services.gemini_service import get_query_embeddings
        from services.aws_db_service import search_products_vector, search_knowledge_base
        
        embedder = get_query_embeddings()
        
        # 1. Test Product Semantic Search
        test_query = "تحفة فنية من الحجر الفرعوني"
        print(f"\n--- Testing Product Semantic Search: '{test_query}' ---")
        embedding = await embedder.aembed_query(test_query)
        products = await search_products_vector(embedding, limit=3)
        if products:
            for p in products:
                # Use float format for distance
                dist = p.get('distance', 0)
                name = p.get('nameAr', 'N/A')
                print(f"Product: {name} | Similarity: {1.0 - dist:.3f}")
        else:
            print("No products found.")

        # 2. Test Knowledge RAG Search
        test_rag = "من هو رمسيس الثاني؟"
        print(f"\n--- Testing Knowledge RAG Search: '{test_rag}' ---")
        rag_embed = await embedder.aembed_query(test_rag)
        docs = await search_knowledge_base(rag_embed, limit=2)
        if docs:
            for d in docs:
                source = d.get('metadata', {}).get('source', 'Knowledge Base')
                snippet = d.get('text_content', '')[:100].replace('\n', ' ')
                print(f"Source: {source} | Snippet: {snippet}...")
        else:
            print("No knowledge base docs found.")
            
    except Exception as e:
        import traceback
        print(f"Verification Error: {e}")
        traceback.print_exc()

if __name__ == '__main__':
    asyncio.run(test_semantic_search())
