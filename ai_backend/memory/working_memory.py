"""
⚡ Working Memory — الذاكرة العاملة (قصيرة المدى)
بتحتفظ بسياق الجلسة الحالية في الذاكرة (RAM).
تُمسح عند إعادة تشغيل السيرفر.
✅ Fixed: should_summarize renamed to avoid collision with summarizer.py
"""
import logging
from datetime import datetime, timedelta
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, messages_from_dict, messages_to_dict
from config import MAX_CONVERSATION_HISTORY
from memory.aws_memory import get_session_data, save_session_data

logger = logging.getLogger(__name__)

# ============================================================
# تخزين الجلسات (Serverless / DynamoDB) Cache
# ============================================================

_sessions_cache: dict[str, dict] = {}


def get_session(session_id: str) -> dict:
    """الحصول على الجلسة من الذاكرة أو جلبها من DynamoDB."""
    if session_id in _sessions_cache:
        return _sessions_cache[session_id]

    data = get_session_data(session_id)
    if data:
        # استرجاع الرسائل باستخدام LangChain utils
        try:
            data["messages"] = messages_from_dict(data.get("messages", []))
        except Exception as e:
            logger.warning(f"Error parsing messages for session {session_id}: {e}")
            data["messages"] = []
        _sessions_cache[session_id] = data
        return data

    new_session = {
        "messages": [],
        "user_id": "",
        "topics": [],
        "products_mentioned": [],
        "last_agent": "",
        "current_sentiment": "neutral",
        "message_count": 0,
        "summary": "",
        "memory_loaded": False,
        "episode_context": "",
        "preferences_context": "",
        "started_at": datetime.utcnow().isoformat(),
        "last_activity": datetime.utcnow().isoformat(),
        "metadata": {},
    }
    _sessions_cache[session_id] = new_session
    return new_session


def commit_session(session_id: str):
    """حفظ الجلسة في DynamoDB (تُستدعى في نهاية دورة الجراف)."""
    if session_id in _sessions_cache:
        data = _sessions_cache[session_id].copy()
        data["last_activity"] = datetime.utcnow().isoformat()
        
        # تحويل الرسائل لـ JSON قابل للحفظ
        try:
            data["messages"] = messages_to_dict(data["messages"])
        except Exception as e:
            logger.warning(f"Error serializing messages: {e}")
            data["messages"] = []
        save_session_data(session_id, data)



def add_message(session_id: str, message: BaseMessage):
    """إضافة رسالة للجلسة مع تقليم تلقائي."""
    session = get_session(session_id)
    session["messages"].append(message)
    session["message_count"] += 1

    # تقليم الرسائل القديمة
    if len(session["messages"]) > MAX_CONVERSATION_HISTORY:
        # نحتفظ بأول رسالة (ترحيب) + آخر N-1 رسالة
        session["messages"] = (
            session["messages"][:1] +
            session["messages"][-(MAX_CONVERSATION_HISTORY - 1):]
        )


def get_messages(session_id: str) -> list[BaseMessage]:
    """الحصول على رسائل الجلسة."""
    session = get_session(session_id)
    return session["messages"]


def get_conversation_context(session_id: str) -> str:
    """بناء نص سياق المحادثة الحالية — يتقدم للوكيل."""
    session = get_session(session_id)
    messages = session["messages"]

    if not messages:
        return ""

    # آخر 6 رسائل كسياق
    recent = messages[-6:]
    context_parts = []
    for msg in recent:
        if isinstance(msg, HumanMessage):
            context_parts.append(f"المستخدم: {msg.content}")
        elif isinstance(msg, AIMessage):
            # نقص على أول 200 حرف
            text = msg.content[:200] + "..." if len(msg.content) > 200 else msg.content
            context_parts.append(f"المساعد: {text}")

    return "\n".join(context_parts)


def get_conversation_text(session_id: str) -> str:
    """تصدير المحادثة كنص كامل — للتلخيص وتعلم التفضيلات."""
    session = get_session(session_id)
    messages = session["messages"]

    if not messages:
        return ""

    parts = []
    for msg in messages[-20:]:  # آخر 20 رسالة
        if isinstance(msg, HumanMessage):
            parts.append(f"المستخدم: {msg.content}")
        elif isinstance(msg, AIMessage):
            text = msg.content[:300] if len(msg.content) > 300 else msg.content
            parts.append(f"المساعد: {text}")

    return "\n".join(parts)


def get_summary(session_id: str) -> str:
    """الحصول على ملخص الجلسة الحالية."""
    session = get_session(session_id)
    return session.get("summary", "")


def set_summary(session_id: str, summary: str):
    """تعيين ملخص الجلسة الحالية."""
    session = get_session(session_id)
    session["summary"] = summary


def is_memory_loaded(session_id: str) -> bool:
    """هل تم تحميل الذاكرة طويلة المدى لهذه الجلسة؟"""
    session = get_session(session_id)
    return session.get("memory_loaded", False)


def mark_memory_loaded(session_id: str):
    """تعليم أن الذاكرة طويلة المدى تم تحميلها."""
    session = get_session(session_id)
    session["memory_loaded"] = True


def set_long_term_context(session_id: str, episode_ctx: str, prefs_ctx: str):
    """تخزين سياق الذاكرة طويلة المدى في الجلسة."""
    session = get_session(session_id)
    session["episode_context"] = episode_ctx
    session["preferences_context"] = prefs_ctx


def get_long_term_context(session_id: str) -> tuple[str, str]:
    """الحصول على سياق الذاكرة طويلة المدى."""
    session = get_session(session_id)
    return (
        session.get("episode_context", ""),
        session.get("preferences_context", ""),
    )


def update_session_metadata(session_id: str, **kwargs):
    """تحديث بيانات الجلسة."""
    session = get_session(session_id)
    for key, value in kwargs.items():
        if key == "topics" and isinstance(value, str):
            if value not in session.get("topics", []):
                session.setdefault("topics", []).append(value)
        elif key == "products_mentioned" and isinstance(value, str):
            if value not in session.get("products_mentioned", []):
                session.setdefault("products_mentioned", []).append(value)
        else:
            session[key] = value


def get_session_summary(session_id: str) -> dict:
    """ملخص سريع للجلسة — مفيد لتحديث المنسق."""
    session = get_session(session_id)
    return {
        "message_count": session["message_count"],
        "topics": session.get("topics", []),
        "products_mentioned": session.get("products_mentioned", []),
        "last_agent": session.get("last_agent", ""),
        "sentiment": session.get("current_sentiment", "neutral"),
        "summary": session.get("summary", ""),
    }


def should_summarize(session_id: str) -> bool:
    """هل الوقت مناسب لتلخيص المحادثة؟ (session-based check)
    
    Note: This is distinct from summarizer.should_summarize(message_count: int).
    This checks using DynamoDB session state directly.
    """
    from config import SUMMARY_AFTER_MESSAGES
    session = get_session(session_id)
    count = session["message_count"]
    return count > 0 and count % SUMMARY_AFTER_MESSAGES == 0


def clear_session(session_id: str):
    """مسح جلسة من الكاش، (مسحها من DynamoDB يحتاج دالة إضافية إن أردت)."""
    if session_id in _sessions_cache:
        del _sessions_cache[session_id]

def get_active_sessions_count() -> int:
    """عدد الجلسات في الكاش."""
    return len(_sessions_cache)
