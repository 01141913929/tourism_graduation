"""
🇪🇬 Egyptian Tourism AI — Main Application
Entry point + App Factory
"""
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from config import HOST, PORT, DEBUG, validate_config
from rag.engine import initialize_rag
from graph.workflow import get_workflow
from api.routes import router as api_router
from api.stream import router as stream_router
from api.websocket import router as ws_router
from api.recommendations import router as rec_router
from api.owner_ai import router as owner_ai_router
from api.admin_ai import router as admin_ai_router
from api.middleware import (
    RateLimitMiddleware,
    RequestLoggingMiddleware,
    ErrorHandlingMiddleware,
)


# ============================================================
# Lifecycle — التهيئة والإغلاق
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """تهيئة كل الأنظمة عند بدء السيرفر."""
    print("🚀 جاري تشغيل Egyptian Tourism AI Backend...")
    print("=" * 50)

    # 1. التحقق من الإعدادات
    validate_config()

    # 2. تهيئة RAG
    await initialize_rag()

    # 4. تجميع الجراف
    get_workflow()

    print("=" * 50)
    print("✅ كل الأنظمة جاهزة!")
    print(f"🌐 السيرفر شغال على: http://{HOST}:{PORT}")
    print(f"📖 التوثيق: http://{HOST}:{PORT}/docs")
    print(f"🔌 WebSocket: ws://{HOST}:{PORT}/ws/chat/{{session_id}}")
    print("=" * 50)

    yield

    print("👋 السيرفر بيقفل...")


# ============================================================
# App Factory
# ============================================================

app = FastAPI(
    title="🇪🇬 Egyptian Tourism AI",
    description="نظام ذكاء اصطناعي متعدد الوكلاء للسياحة المصرية والتجارة الإلكترونية",
    version="2.0.0",
    lifespan=lifespan,
)

# ============ Middleware ============
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(ErrorHandlingMiddleware)
app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(RateLimitMiddleware)

# ============ Routers ============
app.include_router(api_router)
app.include_router(stream_router)
app.include_router(ws_router)
app.include_router(rec_router)
app.include_router(owner_ai_router)
app.include_router(admin_ai_router)


# ============ Root Endpoints ============

@app.get("/")
async def root():
    return {
        "name": "🇪🇬 Egyptian Tourism AI",
        "version": "2.0.0",
        "status": "running",
        "agents": [
            "supervisor", "product", "history", "cart",
            "tour_guide", "web_research", "personalization", "general",
            "owner_assistant", "admin_assistant", "moderation",
        ],
        "features": [
            "Multi-Agent System",
            "3-Layer Memory",
            "Hybrid RAG (BM25 + Vector)",
            "Smart Caching",
            "SSE Streaming",
            "Fallback Chain (Groq → Gemini → Emergency)",
            "Rich Cards",
            "Conversation Summarization",
            "Sentiment Analysis",
            "Proactive Suggestions",
            "WebSocket Streaming",
            "Owner AI Assistant (8 APIs)",
            "Admin AI Assistant (7 APIs)",
            "AI Content Moderation",
            "AI Analytics & Forecasting",
            "AI Business Intelligence",
        ],
    }


@app.get("/health")
async def health():
    from memory.working_memory import get_active_sessions_count
    from rag.engine import get_hybrid_retriever

    rag_ready = get_hybrid_retriever() is not None
    return {
        "status": "healthy" if rag_ready else "degraded",
        "rag": "ready" if rag_ready else "not initialized",
        "active_sessions": get_active_sessions_count(),
    }


@app.post("/api/rag/sync")
async def sync_rag():
    """🔄 إعادة تحميل بيانات الـ RAG."""
    await initialize_rag()
    return {"status": "synced"}


# ============================================================
# Entry Point
# ============================================================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=HOST,
        port=PORT,
        reload=DEBUG,
    )
