"""
🚀 RAG Engine (Serverless Optimized)
يعتمد حصرياً على AWS Aurora pgvector لسرعة الأداء.
بدون استهلاك للذاكرة أو بطء في إقلاع الـ Lambda (Zero Cold Start).
"""
from services.gemini_service import get_embeddings
from memory.aws_memory import search_knowledge_pgvector
from langchain_core.documents import Document
from config import TOP_K_RESULTS
from rag.corrective_rag import corrective_rag_pipeline

class ServerlessRetriever:
    """Retriever وهمي يحاكي الـ HybridRetriever القديم، لكنه متصل بـ pgvector فوراً"""
    @property
    def is_ready(self) -> bool:
        # قاعدة البيانات دائماً جاهزة بإذن الله
        return True
        
    async def search(self, query: str, top_k: int = TOP_K_RESULTS) -> list[tuple[Document, float]]:
        embedder = get_embeddings()
        try:
            # تحويل النص لـ Vector واستدعاء Aurora عبر aws_memory
            embedding = await embedder.aembed_query(query)
            results = search_knowledge_pgvector(embedding, top_k)
            return [
                (Document(page_content=r["content"], metadata={"source": r["source"]}), r["score"])
                for r in results
            ]
        except Exception as e:
            print(f"⚠️ pgvector search error: {e}")
            return []

# Singleton instance
_retriever = ServerlessRetriever()

async def initialize_rag():
    """في بيئة الـ Serverless لا نحتاج لتهيئة (In-Memory). البيانات في Aurora أصلاً!"""
    print("✅ نظام RAG تمت تهيئته! (Serverless Native Aurora pgvector)")

def get_hybrid_retriever() -> ServerlessRetriever:
    return _retriever

async def search_knowledge(query: str, context: str = "") -> str:
    """نقطة الدخول الرئيسية للبحث في قاعدة المعرفة — يستخدمها الوكلاء."""
    if not _retriever.is_ready:
        return "⚠️ نظام RAG غير متصل."

    # استخدام الـ Corrective RAG (CRAG) كالسابق للتقييم والبحث في الويب إن لزم
    result = await corrective_rag_pipeline(query, _retriever, context)

    if not result["documents"]:
        return "لم يتم العثور على معلومات ذات صلة."

    docs_text = "\n\n".join([
        doc.page_content for doc in result["documents"][:TOP_K_RESULTS]
    ])

    # معلومات عن طريقة البحث
    info = f"📖 طريقة البحث: {result['method']} (Aurora pgvector)"
    if result["web_used"]:
        info += " (تم استخدام بحث الويب للطوارئ)"
    if result["rewritten"]:
        info += f"\n🔄 الاستعلام المحسّن: {result['query_used']}"

    return f"{info}\n📊 درجة الارتباط: {result['score']:.1f}\n\n{docs_text}"

async def incremental_update(documents: list) -> None:
    """
    متروكة كـ Placeholder. في الإنتاج، رفع الملفات يكون عبر S3 Event لـ Lambda
    منفصلة تقوم بعمل Embed وحفظها في pgvector knowledge_chunks.
    """
    print("⚠️ Incremental Update called. In AWS this should be handled by an S3 Trigger.")
    pass
