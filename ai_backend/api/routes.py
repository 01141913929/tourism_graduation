"""
🌐 API Routes — REST endpoints مع Smart Cache
✅ Fixed: HIGH-03 — chat_history in initial state, migrated to logging
"""
import time
import logging
from fastapi import APIRouter, HTTPException
from langchain_core.messages import HumanMessage

from models.chat import ChatRequest, ChatResponse, QuickAction
from graph.workflow import get_workflow
from memory.working_memory import get_session_summary, get_active_sessions_count, commit_session
from services.cache_service import get_cache

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Chat"])


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """💬 نقطة الدخول الرئيسية للمحادثة — مع Smart Cache."""
    start = time.time()

    # === فحص الـ Cache أولاً ===
    cache = get_cache()
    cached = cache.get(request.message, user_id=request.user_id or "")
    if cached:
        elapsed = (time.time() - start) * 1000
        logger.info(f"⚡ Cache hit! ({elapsed:.0f}ms)")
        return ChatResponse(
            text=cached.get("text", ""),
            cards=cached.get("cards", []),
            quick_actions=[
                QuickAction(**qa) for qa in cached.get("quick_actions", [])
            ],
            sources=cached.get("sources", []),
            agent_used=cached.get("agent", ""),
            sentiment=cached.get("sentiment", "neutral"),
        )

    # === تشغيل الجراف ===
    try:
        graph = get_workflow()

        import asyncio
        result = await asyncio.wait_for(
            graph.ainvoke({
                "messages": [HumanMessage(content=request.message)],
                "session_id": request.session_id,
                "user_id": request.user_id or "",
                # HIGH-03 Fix: include chat_history in initial state
                "chat_history": [],
                "current_agent": "",
                "agent_output": "",
                "final_response": "",
                "cards": [],
                "quick_actions": [],
                "sources": [],
                "memory_context": "",
                "conversation_summary": "",
                "sentiment": "neutral",
                "proactive_suggestions": [],
                "user_preferences": {},
                "user_language": "",
                # Context Hand-off fields
                "current_viewed_items": [],
                "last_search_query": "",
            }),
            timeout=50.0
        )

        response_data = {
            "text": result.get("final_response", "عذراً، حدث خطأ."),
            "agent": result.get("current_agent", ""),
            "quick_actions": result.get("quick_actions", []),
            "sources": result.get("sources", []),
            "sentiment": result.get("sentiment", "neutral"),
            "cards": result.get("cards", []),
        }

        # === تخزين في الـ Cache ===
        cache.set(request.message, response_data, user_id=request.user_id or "")

        # حفظ الذاكرة في DynamoDB
        commit_session(request.session_id)

        elapsed = (time.time() - start) * 1000
        logger.info(f"✅ Response in {elapsed:.0f}ms | Agent: {response_data['agent']}")

        return ChatResponse(
            text=response_data["text"],
            cards=response_data["cards"],
            quick_actions=[
                QuickAction(**qa) for qa in response_data["quick_actions"]
            ],
            sources=response_data["sources"],
            agent_used=response_data["agent"],
            sentiment=response_data["sentiment"],
        )

    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chat/history/{session_id}")
async def get_chat_history(session_id: str):
    """📋 الحصول على ملخص سجل الجلسة."""
    summary = get_session_summary(session_id)
    return {
        "session_id": session_id,
        "summary": summary,
    }


@router.get("/stats")
async def get_stats():
    """📊 إحصائيات النظام مع الـ Cache."""
    cache = get_cache()
    return {
        "active_sessions": get_active_sessions_count(),
        "cache": cache.stats,
        "status": "running",
    }


@router.delete("/cache")
async def clear_cache():
    """🗑️ مسح الـ Cache."""
    cache = get_cache()
    cache.clear()
    return {"status": "cache cleared"}
