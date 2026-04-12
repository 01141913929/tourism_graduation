"""
🛍️ Product Agent — وكيل المنتجات
خبير تسوق في الأسواق والبازارات المصرية
✅ يستخدم Tool Calling للبحث الذكي في المنتجات
✅ RAG ذكي — فقط لأسئلة المعلومات (مش CRUD)
✅ يدعم Multi-turn context
✅ يكتب current_viewed_items في الـ State (Context Hand-off)
✅ يبني Rich Cards مع product_id و add-to-cart actions
"""
import re
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import PRODUCT_AGENT_PROMPT
from tools.all_tools import PRODUCT_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage
from rag.engine import search_knowledge
from models.structured_output import ProductCard, ViewedItemsContext, product_from_firestore


# كلمات عمليات CRUD — مش محتاجة RAG
_CRUD_KEYWORDS = [
    "أضف", "ضيف", "حط", "سلة", "احذف", "شيل", "كم", "سعر",
    "أعرض", "عرض", "قارن", "add", "remove", "cart", "compare", "show",
]


def _needs_rag(message: str) -> bool:
    """هل السؤال محتاج RAG؟ أسئلة المعلومات = True، عمليات CRUD = False."""
    msg_lower = message.lower()
    crud_count = sum(1 for kw in _CRUD_KEYWORDS if kw in msg_lower)
    return crud_count == 0  # لو مفيش كلمات CRUD → محتاج RAG


def _extract_product_cards_from_text(text: str) -> list[ProductCard]:
    """استخراج كروت المنتجات من نص رد الأدوات باستخدام [ID:xxx] tags.

    يبحث عن أنماط مثل:
    - 🆔 [ID:abc123]
    - [ID:abc123]

    ثم يربطها بالأسماء والأسعار المذكورة في نفس القسم.
    """
    if not text:
        return []

    cards: list[ProductCard] = []

    # نبحث عن كل [ID:xxx] في النص
    id_pattern = re.compile(r'\[ID:([^\]]+)\]')
    id_matches = list(id_pattern.finditer(text))

    if not id_matches:
        return []

    # نبحث عن الأسماء والأسعار المرتبطة بكل ID
    for idx, match in enumerate(id_matches, 1):
        product_id = match.group(1).strip()
        if not product_id:
            continue

        # نأخذ النص قبل الـ ID (من الـ ID السابق أو من بداية النص)
        start_pos = id_matches[idx - 2].end() if idx > 1 else 0
        end_pos = match.start()
        section = text[start_pos:end_pos]

        # استخراج الاسم (أول **bold** text)
        name_match = re.search(r'\*\*([^*]+)\*\*', section)
        name_ar = name_match.group(1).strip() if name_match else f"منتج {idx}"

        # استخراج السعر
        price_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:جنيه|ج\b)', section)
        price = float(price_match.group(1)) if price_match else 0.0

        # استخراج السعر القديم
        old_price_match = re.search(r'~~(\d+(?:\.\d+)?)~~', section)
        old_price = float(old_price_match.group(1)) if old_price_match else None

        # استخراج القسم
        cat_match = re.search(r'القسم:\s*([^\n—-]+)', section)
        category = cat_match.group(1).strip() if cat_match else ""

        # استخراج البازار
        bazaar_match = re.search(r'بازار:\s*([^\n—-]+)', section)
        bazaar_name = bazaar_match.group(1).strip() if bazaar_match else ""

        # استخراج التقييم
        rating_match = re.search(r'(\d+(?:\.\d+)?)/5', section)
        rating = float(rating_match.group(1)) if rating_match else 0.0

        # استخراج رابط الصورة
        img_match = re.search(r'!\[.*?\]\(([^)]+)\)', section)
        image_url = img_match.group(1).strip() if img_match else ""

        try:
            card = ProductCard(
                index=idx,
                product_id=product_id,
                name_ar=name_ar,
                price=price,
                old_price=old_price,
                category=category,
                bazaar_name=bazaar_name,
                rating=rating,
                image_url=image_url,
            )
            cards.append(card)
        except Exception as e:
            print(f"⚠️ خطأ في بناء ProductCard: {e}")
            continue

    return cards


async def run_product_agent(state: AgentState) -> dict:
    """تشغيل وكيل المنتجات — Tool Calling + RAG ذكي + Multi-turn + Context Hand-off."""

    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""

    # === بناء السياق الإضافي ===
    extra_parts = []

    # بحث RAG — فقط لأسئلة المعلومات
    if _needs_rag(last_msg):
        try:
            rag_context = await asyncio.wait_for(
                search_knowledge(f"منتجات {last_msg}"),
                timeout=15.0,
            )
            if rag_context:
                extra_parts.append(f"\n\n--- معلومات من قاعدة المعرفة ---\n{rag_context}")
        except (asyncio.TimeoutError, Exception):
            pass

    # Multi-turn context — آخر 3 رسائل
    if len(messages) > 1:
        history_lines = []
        for msg in messages[-4:-1]:  # آخر 3 قبل الرسالة الحالية
            role = "المستخدم" if msg.type == "human" else "المساعد"
            content = msg.content[:150]  # اختصار
            history_lines.append(f"  {role}: {content}")
        if history_lines:
            extra_parts.append(f"\n\n--- سياق المحادثة السابقة ---\n" + "\n".join(history_lines))

    # سياق الذاكرة
    memory_ctx = state.get("memory_context", "")
    if memory_ctx:
        extra_parts.append(f"\n\n--- سياق المستخدم ---\n{memory_ctx}")

    # تعليمات اللغة
    user_lang = state.get("user_language", "ar")
    from services.language_service import get_language_instruction
    lang_instruction = get_language_instruction(user_lang)
    if lang_instruction:
        extra_parts.append(lang_instruction)

    # تفضيلات المستخدم
    prefs = state.get("user_preferences", {})
    if prefs.get("favorite_categories"):
        cats = ", ".join(prefs["favorite_categories"][:3])
        extra_parts.append(f"\n\nالمستخدم يحب: {cats}. اقترح منتجات من الفئات دي لو مناسب.")

    extra_context = "".join(extra_parts)

    session_id = state.get("session_id", "default")
    user_id = state.get("user_id", "default")

    # === تشغيل الوكيل مع الأدوات ===
    try:
        response = await run_agent_with_tools(
            system_prompt=PRODUCT_AGENT_PROMPT,
            user_message=last_msg,
            tools=PRODUCT_TOOLS,
            context=extra_context,
            session_id=session_id,
            user_id=user_id,
            agent_name="product_agent",
        )
    except Exception as e:
        print(f"❌ Product agent error: {e}")
        response = "عذراً، حدث خطأ في البحث عن المنتجات."

    # === Context Hand-off: استخراج المنتجات وكتابتها في الـ State ===
    viewed_cards = _extract_product_cards_from_text(response)
    viewed_items_dicts = [card.model_dump() for card in viewed_cards]

    # بناء Rich Cards من المنتجات المستخرجة
    rich_cards = [card.to_rich_card() for card in viewed_cards]

    return {
        "agent_output": response,
        "current_agent": "product_agent",
        "current_viewed_items": viewed_items_dicts,  # ← Context Hand-off!
        "last_search_query": last_msg,
        "cards": rich_cards,  # ← Rich Cards مع product_id
        "messages": [AIMessage(content=response, name="product_agent")],
    }
