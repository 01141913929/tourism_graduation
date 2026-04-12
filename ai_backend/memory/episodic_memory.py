"""
📝 Episodic Memory — الذاكرة العرضية (متوسطة المدى)
بتخزن ملخصات المحادثات السابقة في Firestore.
بعد كل محادثة طويلة، الـ AI بيلخص الجلسة ويحفظها.
"""
from services.gemini_service import get_llm
from services import aws_db_service as db


# ============================================================
# تلخيص المحادثة
# ============================================================

async def summarize_conversation(messages_text: str, session_id: str) -> str:
    """تلخيص محادثة كاملة باستخدام Gemini."""
    if not messages_text or len(messages_text.strip()) < 50:
        return ""

    llm = get_llm(temperature=0.2)

    prompt = f"""لخّص هذه المحادثة في 2-3 جمل مركزة بالعربية.
اذكر: المواضيع الرئيسية، المنتجات المذكورة، الأسئلة المطروحة، والقرارات المتخذة.

المحادثة:
{messages_text[:3000]}

الملخص:"""

    try:
        response = await llm.ainvoke(prompt)
        return response.content.strip()
    except Exception as e:
        print(f"⚠️ خطأ في تلخيص المحادثة: {e}")
        return ""


async def extract_topics(messages_text: str) -> list[str]:
    """استخراج المواضيع من المحادثة."""
    if not messages_text or len(messages_text.strip()) < 50:
        return []

    llm = get_llm(temperature=0.0)

    prompt = f"""استخرج المواضيع الرئيسية من هذه المحادثة.
أعد قائمة بالمواضيع فقط، كل موضوع في سطر، بدون ترقيم.

المحادثة:
{messages_text[:2000]}

المواضيع:"""

    try:
        response = await llm.ainvoke(prompt)
        topics = [t.strip() for t in response.content.strip().split("\n") if t.strip()]
        return topics[:5]  # أقصى 5 مواضيع
    except Exception as e:
        print(f"⚠️ خطأ في استخراج المواضيع: {e}")
        return []


# ============================================================
# حفظ وتحميل الحلقات
# ============================================================

async def save_episode(user_id: str, session_id: str,
                       summary: str, topics: list[str],
                       sentiment: str = "neutral",
                       message_count: int = 0):
    """حفظ حلقة محادثة في Firestore."""
    if not user_id or not summary:
        return

    try:
        from datetime import datetime
        # حفظ الملخص كحلقة
        await db.save_conversation_summary(user_id, summary)

        print(f"💾 تم حفظ حلقة ذاكرة للمستخدم {user_id[:8]} في AWS DynamoDB...")
    except Exception as e:
        print(f"⚠️ خطأ في حفظ الحلقة: {e}")


async def load_recent_episodes(user_id: str, limit: int = 5) -> list[dict]:
    """تحميل آخر N حلقات محادثة."""
    if not user_id:
        return []

    try:
        summaries = await db.get_conversation_summaries(user_id, limit)
        return [{"summary": s} for s in summaries]
    except Exception as e:
        print(f"⚠️ خطأ في تحميل الحلقات: {e}")
        return []


async def get_episode_context(user_id: str) -> str:
    """بناء سياق من الحلقات السابقة — يتقدم للوكلاء."""
    episodes = await load_recent_episodes(user_id, limit=3)
    if not episodes:
        return ""

    parts = ["📋 محادثات سابقة مع هذا المستخدم:"]
    for ep in episodes:
        summary = ep.get("summary", "")
        if summary:
            parts.append(f"  - {summary}")

    return "\n".join(parts) if len(parts) > 1 else ""


# ============================================================
# إنهاء الجلسة — تلخيص تلقائي + حفظ
# ============================================================

async def finalize_session(user_id: str, session_id: str,
                           messages_text: str, sentiment: str = "neutral",
                           message_count: int = 0) -> str:
    """تلخيص وحفظ الجلسة عند الانتهاء أو كل 15 رسالة."""
    if not user_id or not messages_text:
        return ""

    try:
        # تلخيص المحادثة
        summary = await summarize_conversation(messages_text, session_id)
        if not summary:
            return ""

        topics = await extract_topics(messages_text)

        # حفظ الحلقة
        await save_episode(
            user_id=user_id,
            session_id=session_id,
            summary=summary,
            topics=topics,
            sentiment=sentiment,
            message_count=message_count,
        )

        print(f"📝 تم تلخيص وحفظ الجلسة: {summary[:80]}...")
        return summary
    except Exception as e:
        print(f"⚠️ خطأ في إنهاء الجلسة: {e}")
        return ""
