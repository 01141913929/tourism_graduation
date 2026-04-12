"""
🛍️ Commerce Agent — وكيل التجارة الموحد
يجمع بين البحث عن المنتجات (Product) وإدارة السلة (Cart) لأقصى سرعة
✅ يستخدم Tool Calling لعمليات المتجر والسلة
✅ يكتب ويقرأ current_viewed_items من הـ State مباشرة (Context Hand-off)
"""
import re
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import COMMERCE_AGENT_PROMPT
from tools.all_tools import PRODUCT_TOOLS, CART_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage
from rag.engine import search_knowledge
from models.structured_output import ProductCard

# دمج كل أدوات التجارة والسلة
COMMERCE_TOOLS = PRODUCT_TOOLS + CART_TOOLS

_CRUD_KEYWORDS = [
    "أضف", "ضيف", "حط", "سلة", "احذف", "شيل", "كم", "سعر",
    "أعرض", "عرض", "قارن", "add", "remove", "cart", "compare", "show",
]

def _needs_rag(message: str) -> bool:
    """هل السؤال محتاج RAG؟ أسئلة المعلومات = True، عمليات السلة والأسعار = False."""
    msg_lower = message.lower()
    crud_count = sum(1 for kw in _CRUD_KEYWORDS if kw in msg_lower)
    return crud_count == 0

def _extract_product_cards_from_text(text: str) -> list[ProductCard]:
    """استخراج كروت المنتجات من الرد (كما في وكيل المنتجات القديم)."""
    if not text: return []
    cards: list[ProductCard] = []
    id_pattern = re.compile(r'\[ID:([^\]]+)\]')
    id_matches = list(id_pattern.finditer(text))

    for idx, match in enumerate(id_matches, 1):
        product_id = match.group(1).strip()
        if not product_id: continue

        start_pos = id_matches[idx - 2].end() if idx > 1 else 0
        section = text[start_pos:match.start()]
        
        name_match = re.search(r'\*\*([^*]+)\*\*', section)
        name_ar = name_match.group(1).strip() if name_match else f"منتج {idx}"
        
        price_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:جنيه|ج\b)', section)
        price = float(price_match.group(1)) if price_match else 0.0
        
        old_price_match = re.search(r'~~(\d+(?:\.\d+)?)~~', section)
        old_price = float(old_price_match.group(1)) if old_price_match else None
        
        cat_match = re.search(r'القسم:\s*([^\n—-]+)', section)
        category = cat_match.group(1).strip() if cat_match else ""
        
        bazaar_match = re.search(r'بازار:\s*([^\n—-]+)', section)
        bazaar_name = bazaar_match.group(1).strip() if bazaar_match else ""
        
        rating_match = re.search(r'(\d+(?:\.\d+)?)/5', section)
        rating = float(rating_match.group(1)) if rating_match else 0.0
        
        img_match = re.search(r'!\[.*?\]\(([^)]+)\)', section)
        image_url = img_match.group(1).strip() if img_match else ""

        try:
            cards.append(ProductCard(
                index=idx, product_id=product_id, name_ar=name_ar, price=price,
                old_price=old_price, category=category, bazaar_name=bazaar_name, 
                rating=rating, image_url=image_url
            ))
        except Exception:
            continue
    return cards

async def run_commerce_agent(state: AgentState) -> dict:
    """تشغيل الوكيل التجاري (يجمع بحث المنتجات + إدارة السلة)."""
    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""
    session_id = state.get("session_id", "default")
    user_id = state.get("user_id", "default")
    chat_history = state.get("chat_history", [])

    extra_parts = []

    # 1. Context Hand-off: قراءة المنتجات المعروضة (حتى لو لسه معروضة دلوقتي)
    viewed_items = state.get("current_viewed_items", [])
    if viewed_items:
        items_lines = []
        for item in viewed_items:
            idx = item.get("index", 0)
            name = item.get("name_ar", "منتج")
            pid = item.get("product_id", "")
            items_lines.append(f" {idx}. {name} (ID: {pid})")
        extra_parts.append(
            f"\n\n🔗 المنتجات التي تم عرضها أو الحديث عنها مؤخراً:\n" + "\n".join(items_lines) +
            f"\n\nالقاعدة: استخدم הـ ID الخاص بالمنتج مباشرة إذا أشار له المستخدم (الأول، التاني، ده)."
        )

    # 2. معلومات أساسية وأمان السلة
    extra_parts.append(f"\n⚠️ User ID الحالي: \"{user_id}\" - ضروري لأي عملية سلة.")

    # 3. RAG 
    if _needs_rag(last_msg):
        try:
            rag_context = await asyncio.wait_for(search_knowledge(f"منتجات {last_msg}"), timeout=10.0)
            if rag_context:
                extra_parts.append(f"\n\n--- قاعدة المعرفة (منتجات) ---\n{rag_context}")
        except Exception:
            pass

    # 4. التفضيلات
    prefs = state.get("user_preferences", {})
    if prefs.get("favorite_categories"):
        extra_parts.append("\nالعميل يفضل: " + ", ".join(prefs["favorite_categories"][:3]))

    # تجميع السياق
    extra_context = "".join(extra_parts)

    try:
        response = await run_agent_with_tools(
            system_prompt=COMMERCE_AGENT_PROMPT,
            user_message=last_msg,
            tools=COMMERCE_TOOLS,
            context=extra_context,
            chat_history=chat_history,
            session_id=session_id,
            user_id=user_id,
            agent_name="commerce_agent"
        )
    except Exception as e:
        print(f"❌ Commerce Agent Error: {e}")
        response = "عذراً، حدث خطأ أثناء الاتصال بالمنتجات أو السلة."

    new_cards = _extract_product_cards_from_text(response)
    
    viewed_items_dicts = viewed_items # Keep previous items 
    rich_cards = []
    
    if new_cards:
        viewed_items_dicts = [c.model_dump() for c in new_cards]
        rich_cards = [c.to_rich_card() for c in new_cards]

    return {
        "agent_output": response,
        "current_agent": "commerce_agent",
        "current_viewed_items": viewed_items_dicts,
        "last_search_query": last_msg,
        "cards": rich_cards,
        "messages": [AIMessage(content=response, name="commerce_agent")],
    }
