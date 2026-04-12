"""
🔀 Graph Nodes — عقد الجراف
كل الدوال اللي بتتنفذ في كل عقدة من LangGraph
✅ Fixed: session_messages bug, reflection returns partial dict, logging
"""
import logging
from graph.state import AgentState
from services.gemini_service import get_llm
from langchain_core.messages import AIMessage

# استيراد كل الوكلاء
from agents.supervisor import run_supervisor
from agents.commerce_agent import run_commerce_agent
from agents.explorer_agent import run_explorer_agent
from agents.assistant_agent import run_assistant_agent
from agents.personalization_agent import run_personalization_agent, analyze_sentiment_quick

logger = logging.getLogger(__name__)


# ============================================================
# عقدة تحميل الذاكرة (أول عقدة بعد الدخول)
# ============================================================

async def memory_loader_node(state: AgentState) -> dict:
    """تحميل ذاكرة المستخدم — تفضيلات + ملخصات سابقة + تحليل مشاعر + كشف لغة."""
    user_id = state.get("user_id", "")
    messages = state.get("messages", [])
    last_message = messages[-1].content if messages else ""

    memory_context = ""
    user_preferences = {}
    sentiment = "neutral"
    conversation_summary = state.get("conversation_summary", "")
    chat_history = []

    # كشف لغة المستخدم (فوري)
    from services.language_service import detect_language
    user_language = detect_language(last_message) if last_message else "ar"

    try:
        # تحميل التفضيلات
        if user_id:
            from memory.semantic_memory import load_preferences, get_preferences_context
            from memory.episodic_memory import get_episode_context

            prefs = await load_preferences(user_id)
            user_preferences = prefs.model_dump()
            prefs_ctx = get_preferences_context(prefs)
            episode_ctx = await get_episode_context(user_id)

            parts = []
            if prefs_ctx:
                parts.append(prefs_ctx)
            if episode_ctx:
                parts.append(episode_ctx)
            memory_context = "\n\n".join(parts)

        # تحليل المشاعر (keyword-based — فوري)
        if last_message:
            sentiment = await analyze_sentiment_quick(last_message)

    except Exception as e:
        logger.warning(f"خطأ في تحميل الذاكرة: {e}")

    # حفظ في الذاكرة العاملة + تلخيص لو لازم
    try:
        from memory.working_memory import (
            add_message, update_session_metadata, get_session,
            should_summarize, get_messages,
        )
        from memory.summarizer import summarize_conversation

        session_id = state.get("session_id", "default")
        if messages:
            add_message(session_id, messages[-1])

        session = get_session(session_id)
        msg_count = session.get("message_count", 0)

        # BUG-01 Fix: get actual messages from working memory
        session_messages = get_messages(session_id)

        # تلخيص المحادثة كل 15 رسالة
        if should_summarize(session_id):
            summary = await summarize_conversation(session_messages)
            if summary:
                conversation_summary = summary
                logger.info(f"📝 تم تلخيص المحادثة ({msg_count} رسالة)")

        # استخراج المحادثات السابقة لتغذية الـ LLM
        # نستثني الرسالة الأخيرة لأنها الرسالة الحالية للمستخدم
        chat_history = session_messages[:-1] if session_messages else []

        update_session_metadata(
            session_id,
            user_id=user_id,
            current_sentiment=sentiment,
            last_agent="",
        )
    except Exception as e:
        logger.warning(f"خطأ في الذاكرة العاملة: {e}")

    return {
        "chat_history": chat_history,
        "memory_context": memory_context,
        "user_preferences": user_preferences,
        "sentiment": sentiment,
        "conversation_summary": conversation_summary,
        "user_language": user_language,
    }


# ============================================================
# عقدة المنسق
# ============================================================

async def supervisor_node(state: AgentState) -> dict:
    """عقدة المنسق — بيوجه الطلب للوكيل المناسب."""
    return await run_supervisor(state)


# ============================================================
# عقد الوكلاء
# ============================================================

async def commerce_agent_node(state: AgentState) -> dict:
    return await run_commerce_agent(state)

async def explorer_agent_node(state: AgentState) -> dict:
    return await run_explorer_agent(state)

async def assistant_agent_node(state: AgentState) -> dict:
    return await run_assistant_agent(state)

async def personalization_agent_node(state: AgentState) -> dict:
    return await run_personalization_agent(state)



# ============================================================
# عقدة المراجعة الذاتية (Score-based — سريعة بدون LLM call)
# ============================================================

# علامات الردود الضعيفة
_WEAK_INDICATORS = [
    "عذراً، حدث خطأ",
    "مش قادر أساعدك",
    "لم يتم العثور",
    "جرب تاني",
    "حدث خطأ مؤقت",
    "لم أتمكن",
]


async def reflection_node(state: AgentState) -> dict:
    """مراجعة وتحسين رد الوكيل — Score-based (سريع بدون LLM call إضافي).

    القواعد:
    1. لو الرد أقل من 30 حرف → إعادة صياغة بـ LLM
    2. لو الرد generic/ضعيف → محاولة تحسين بـ LLM
    3. لو الرد كويس → يمرّ بدون تعديل
    """
    from config import ENABLE_REFLECTION

    if not ENABLE_REFLECTION:
        # MED-01 Fix: Return empty dict (no changes) instead of full state
        return {}

    output = state.get("agent_output", "")
    agent = state.get("current_agent", "")

    if not output:
        return {}

    # === فحص 1: الرد قصير جداً ===
    if len(output.strip()) < 30:
        improved = await _improve_response(output, agent)
        if improved:
            return {"agent_output": improved}
        return {}

    # === فحص 2: الرد generic/ضعيف ===
    output_lower = output.lower()
    is_weak = any(indicator in output_lower for indicator in _WEAK_INDICATORS)

    if is_weak and len(output.strip()) < 100:
        improved = await _improve_response(output, agent)
        if improved and len(improved) > len(output):
            return {"agent_output": improved}

    # === الرد كويس — يمرّ بدون تعديل ===
    return {}


async def _improve_response(output: str, agent: str) -> str | None:
    """محاولة تحسين رد ضعيف — LLM call واحد فقط."""
    import asyncio
    try:
        llm = get_llm(temperature=0.5)
        prompt = (
            f"أنت مساعد سياحة مصرية. الرد التالي ضعيف أو قصير.\n"
            f"حسّنه وأعد نسخة أفضل وأغنى بالمعلومات.\n"
            f"لا تشرح التحسين — أعد الرد المحسن فقط.\n\n"
            f"الرد الأصلي: {output}\n\n"
            f"الرد المحسن:"
        )
        result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=15.0)
        improved = result.content.strip()

        # تحقق أن التحسين فعلاً أحسن
        if improved and len(improved) > 20:
            logger.info(f"🔍 Reflection: تم تحسين رد {agent}")
            return improved
    except Exception as e:
        logger.warning(f"Reflection error: {e}")

    return None


# ============================================================
# عقدة بناء الرد النهائي مع Rich Cards
# ============================================================

async def build_response_node(state: AgentState) -> dict:
    """بناء الرد النهائي مع Rich Cards والإجراءات السريعة.

    ✅ محسّن: يستخدم current_viewed_items لبناء كروت منتجات حقيقية مع product_id
    """
    output = state.get("agent_output", "")
    agent = state.get("current_agent", "")
    sentiment = state.get("sentiment", "neutral")
    suggestions = state.get("proactive_suggestions", [])

    # === Rich Cards حسب الوكيل ===
    # لو الوكيل (مثل commerce_agent) رجّع كروت جاهزة → استخدمها وحميها من الشطب
    existing_cards = state.get("cards", [])
    if existing_cards and agent in ("product_agent", "commerce_agent"):
        cards = existing_cards  # كروت منتجات حقيقية
    else:
        cards = _build_rich_cards(agent, output, state)

    # === إجراءات سريعة حسب الوكيل ===
    quick_actions = _get_quick_actions(agent)

    # === إضافة اقتراحات تلقائية ===
    if suggestions:
        for s in suggestions[:2]:
            quick_actions.append({
                "label": f"{s.get('title', '💡 اقتراح')}",
                "message": s.get("message", ""),
            })

    # === تحديث الذاكرة العاملة ===
    try:
        from memory.working_memory import add_message, update_session_metadata
        session_id = state.get("session_id", "default")
        add_message(session_id, AIMessage(content=output, name=agent))
        update_session_metadata(session_id, last_agent=agent)
    except Exception:
        pass

    return {
        "final_response": output,
        "quick_actions": quick_actions,
        "cards": cards,
        "sources": state.get("sources", []),
    }


# ============================================================
# عقدة تعلم التفضيلات (بعد بناء الرد)
# ============================================================

async def learn_preferences_node(state: AgentState) -> dict:
    """تعلم تفضيلات المستخدم من المحادثة الحالية — يشتغل async بعد الرد."""
    user_id = state.get("user_id", "")
    if not user_id:
        return {}

    messages = state.get("messages", [])
    agent_output = state.get("agent_output", "")
    agent = state.get("current_agent", "")

    # نتعلم فقط من محادثات ذات معنى (مش assistant_agent أو commerce_agent لو كانت سلة فقط)
    if agent in ("assistant_agent",):
        return {}

    # بناء نص المحادثة
    user_msg = messages[-1].content if messages else ""
    conversation_text = f"المستخدم: {user_msg}\nالمساعد: {agent_output}"

    try:
        from memory.semantic_memory import load_preferences, learn_from_conversation, save_preferences
        import asyncio

        async def _background_learn():
            try:
                current_prefs = await load_preferences(user_id)
                updated_prefs = await asyncio.wait_for(
                    learn_from_conversation(user_id, conversation_text, current_prefs),
                    timeout=15.0,
                )
                await save_preferences(user_id, updated_prefs)
                logger.info(f"🧠 تم تحديث تفضيلات المستخدم {user_id}")
            except Exception as e:
                logger.warning(f"خطأ في تعلم التفضيلات في الخلفية: {e}")

        await _background_learn()
    except Exception as e:
        logger.warning(f"خطأ في إطلاق تعلم التفضيلات: {e}")

    return {}


# ============================================================
# بناء Rich Cards — محسّن مع current_viewed_items
# ============================================================

def _build_rich_cards(agent: str, output: str, state: dict = None) -> list[dict]:
    """بناء Rich Cards حسب نوع الوكيل والمحتوى.

    ✅ محسّن: product_agent يستخدم current_viewed_items
    """
    cards = []
    output_lower = output.lower() if output else ""
    state = state or {}

    if agent == "commerce_agent":
        # أولاً: لو فيه current_viewed_items → كروت منتجات حقيقية
        viewed_items = state.get("current_viewed_items", [])
        if viewed_items:
            for item in viewed_items:
                cards.append({
                    "type": "product_card",
                    "data": {
                        "product_id": item.get("product_id", ""),
                        "title": item.get("name_ar", ""),
                        "price": item.get("price", 0),
                        "old_price": item.get("old_price"),
                        "image_url": item.get("image_url", ""),
                        "category": item.get("category", ""),
                        "bazaar_name": item.get("bazaar_name", ""),
                        "rating": item.get("rating", 0),
                    },
                    "actions": [
                        {"label": "🛒 أضف للسلة", "action": "add_to_cart",
                         "params": {"product_id": item.get("product_id", "")}},
                        {"label": "📋 تفاصيل", "action": "send_message",
                         "params": {"message": f"تفاصيل المنتج {item.get('product_id', '')}"}},
                    ],
                })
        else:
            if "سلة" in output_lower or "cart" in output_lower:
                cards.append({
                    "type": "cart_summary",
                    "data": {
                        "title": "🛒 سلة المشتريات",
                        "description": "تم تحديث السلة",
                        "icon": "shopping_cart",
                    },
                    "actions": [
                        {"label": "💳 إتمام الشراء", "action": "navigate", "params": {"screen": "checkout"}},
                        {"label": "🛍️ تسوق أكتر", "action": "send_message", "params": {"message": "عايز أتسوق أكتر"}},
                    ],
                })
            else:
                cards.append({
                    "type": "product",
                    "data": {
                        "title": "🛍️ منتجات مقترحة",
                        "description": "تصفح المنتجات المصرية الأصيلة",
                        "icon": "shopping_bag",
                    },
                    "actions": [
                        {"label": "تصفح المنتجات", "action": "navigate", "params": {"screen": "products"}},
                        {"label": "عروض اليوم", "action": "send_message", "params": {"message": "عروض اليوم"}},
                    ],
                })

    elif agent == "explorer_agent":
        artifact_keywords = {
            "توت عنخ": {"name": "توت عنخ آمون", "area": "المتحف المصري الكبير", "icon": "👑"},
            "رمسيس": {"name": "رمسيس الثاني", "area": "أبو سمبل، أسوان", "icon": "🏛️"},
            "كليوباترا": {"name": "كليوباترا السابعة", "area": "الإسكندرية", "icon": "👸"},
            "أهرام": {"name": "أهرامات الجيزة", "area": "الجيزة", "icon": "🔺"},
            "أبو الهول": {"name": "أبو الهول", "area": "الجيزة", "icon": "🦁"},
            "حتشبسوت": {"name": "حتشبسوت", "area": "الأقصر", "icon": "👑"},
            "خان الخليلي": {"name": "خان الخليلي", "area": "القاهرة القديمة", "icon": "🏪"},
            "أقصر": {"name": "الأقصر", "area": "صعيد مصر", "icon": "🏛️"},
            "أسوان": {"name": "أسوان", "area": "جنوب مصر", "icon": "⛵"},
        }
        for keyword, info in artifact_keywords.items():
            if keyword in output_lower:
                cards.append({
                    "type": "artifact" if "أهرام" in keyword or "رمسيس" in keyword else "bazaar",
                    "data": {
                        "title": f"{info['icon']} {info['name']}",
                        "location": info["area"],
                        "area": info["area"],
                        "description": f"استكشف أكثر حول {info['name']}",
                    },
                    "actions": [
                        {"label": "📍 الموقع والتفاصيل", "action": "navigate", "params": {"location": info["area"]}},
                    ],
                })
                break


    return cards


def _get_quick_actions(agent: str) -> list[dict]:
    """إجراءات سريعة حسب الوكيل المستخدم."""
    actions_map = {
        "commerce_agent": [
            {"label": "🛒 عرض السلة", "message": "عرض السلة"},
            {"label": "🎟️ كوبون خصم", "message": "في كوبونات خصم؟"},
            {"label": "💳 إتمام الشراء", "message": "عايز أكمل عملية الشراء"},
            {"label": "⭐ منتجات مميزة", "message": "أعرض المنتجات المميزة"},
        ],
        "explorer_agent": [
            {"label": "📸 أماكن سياحية", "message": "اقترح أماكن سياحية"},
            {"label": "🏪 بازارات قريبة", "message": "فين أقرب بازار؟"},
            {"label": "🛍️ هدايا من هنا", "message": "منتجات مميزة من المكان ده"},
        ],
        "assistant_agent": [
            {"label": "📜 تاريخ", "message": "احكيلي عن الفراعنة"},
            {"label": "🛍️ تسوق", "message": "عايز أتسوق"},
        ],
        "personalization_agent": [
            {"label": "🛍️ اقتراحات لي", "message": "اقترح حاجات تناسبني"},
            {"label": "📜 حسب اهتماماتي", "message": "عايز حاجات حسب اهتماماتي"},
        ],
    }

    return actions_map.get(agent, [
        {"label": "🛍️ تسوق", "message": "عايز أتسوق"},
        {"label": "📜 تاريخ", "message": "احكيلي عن الفراعنة"},
        {"label": "🗺️ بازارات", "message": "فين أقرب بازار؟"},
    ])
