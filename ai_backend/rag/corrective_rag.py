"""
🔄 Corrective RAG — نظام RAG تصحيحي (مع Query Rewriter)
بحث هجين مع تقييم → إعادة صياغة ذكية → توسيع عربي → Web Fallback
"""
from langchain_core.documents import Document
from config import RELEVANCE_THRESHOLD


async def corrective_rag_pipeline(query: str, hybrid_retriever,
                                   context: str = "") -> dict:
    """Pipeline الـ RAG — مع Query Rewriter مفعّل.

    الخطوات:
    1. بحث هجين مباشر
    2. لو النتائج ضعيفة → إعادة صياغة بـ LLM + بحث ثاني
    3. لو لسه ضعيف → توسيع عربي + بحث ثالث
    4. لو مفيش نتائج → بحث ويب كخطة بديلة
    """
    result = {
        "documents": [],
        "score": 0.0,
        "method": "hybrid",
        "query_used": query,
        "web_used": False,
        "rewritten": False,
        "sources": [],
    }

    # ============ الخطوة 1: بحث هجين مباشر ============
    docs = await hybrid_retriever.search(query)

    if docs:
        relevant_docs = [doc for doc, score in docs if score > 0.3]
        avg_score = sum(s for _, s in docs) / len(docs) if docs else 0.0

        result["documents"] = relevant_docs if relevant_docs else [doc for doc, _ in docs[:3]]
        result["score"] = avg_score

    # ============ الخطوة 2: إعادة صياغة ذكية بـ LLM ============
    if result["score"] < RELEVANCE_THRESHOLD and len(result["documents"]) < 2:
        try:
            from rag.query_rewriter import rewrite_query
            rewritten = await rewrite_query(query, context)

            if rewritten and rewritten != query:
                docs = await hybrid_retriever.search(rewritten)
                if docs:
                    relevant_docs = [doc for doc, score in docs if score > 0.2]
                    avg_score = sum(s for _, s in docs) / len(docs)

                    if avg_score > result["score"]:
                        result["documents"] = relevant_docs if relevant_docs else [doc for doc, _ in docs[:3]]
                        result["score"] = avg_score
                        result["query_used"] = rewritten
                        result["method"] = "hybrid_rewritten"
                        result["rewritten"] = True
        except Exception as e:
            print(f"⚠️ Query rewrite failed: {e}")

    # ============ الخطوة 3: توسيع عربي ============
    if result["score"] < RELEVANCE_THRESHOLD and len(result["documents"]) < 2:
        try:
            from rag.query_rewriter import expand_arabic_query
            expanded = await expand_arabic_query(query)

            if expanded and expanded != query:
                docs = await hybrid_retriever.search(expanded)
                if docs:
                    relevant_docs = [doc for doc, score in docs if score > 0.15]
                    avg_score = sum(s for _, s in docs) / len(docs)

                    if avg_score > result["score"]:
                        result["documents"] = relevant_docs if relevant_docs else [doc for doc, _ in docs[:3]]
                        result["score"] = avg_score
                        result["query_used"] = expanded
                        result["method"] = "hybrid_expanded"
                        result["rewritten"] = True
        except Exception as e:
            print(f"⚠️ Query expansion failed: {e}")

    # ============ الخطوة 4: بحث ويب كخطة بديلة ============
    if not result["documents"]:
        result["web_used"] = True
        result["method"] = "web_fallback"
        try:
            from tools.web_tools import web_search
            web_result = await web_search.ainvoke({"query": query})
            result["documents"] = [
                Document(page_content=web_result, metadata={"source": "web"})
            ]
            result["score"] = 0.8
        except Exception as e:
            print(f"⚠️ فشل بحث الويب: {e}")

    return result
