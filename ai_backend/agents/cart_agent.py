"""
🛒 Cart Agent — وكيل سلة المشتريات
مساعد تسوق ذكي وسريع
✅ يستخدم Tool Calling لتنفيذ عمليات السلة فعلياً
✅ يقرأ current_viewed_items من الـ State (Context Hand-off)
✅ يفهم "الأول" و"التاني" و"ده" عن طريق السياق
"""
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import CART_AGENT_PROMPT
from tools.all_tools import CART_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage


async def run_cart_agent(state: AgentState) -> dict:
    """تشغيل وكيل السلة — Tool Calling + Context Hand-off من المنتجات المعروضة."""

    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""
    session_id = state.get("session_id", "default")
    user_id = state.get("user_id", "default")

    # === بناء السياق ===
    extra_parts = []

    # سياق الذاكرة
    memory_ctx = state.get("memory_context", "")
    if memory_ctx:
        extra_parts.append(f"\n\n--- سياق المستخدم ---\n{memory_ctx}")

    # تمرير الـ user_id عشان الأدوات تشتغل على حساب المستخدم الصح
    extra_parts.append(
        f"\n\n⚠️ معلومة مهمة: معرف المستخدم الحالي (user_id) هو \"{user_id}\". "
        f"استخدمه كـ parameter في أدوات السلة."
    )

    # === Context Hand-off: قراءة المنتجات المعروضة من الوكيل السابق ===
    viewed_items = state.get("current_viewed_items", [])
    if viewed_items:
        items_lines = []
        for item in viewed_items:
            idx = item.get("index", 0)
            name = item.get("name_ar", "منتج")
            pid = item.get("product_id", "")
            price = item.get("price", 0)
            items_lines.append(f"  {idx}. {name} — ID: {pid} — السعر: {price} ج")

        items_text = "\n".join(items_lines)
        extra_parts.append(
            f"\n\n🔗 المنتجات المعروضة حالياً أمام المستخدم:\n"
            f"{items_text}\n\n"
            f"📌 قواعد مهمة:\n"
            f"- عندما يقول المستخدم 'الأول' يقصد المنتج رقم 1 من القائمة أعلاه.\n"
            f"- عندما يقول 'التاني' يقصد المنتج رقم 2.\n"
            f"- عندما يقول 'ده' أو 'هو ده' يقصد آخر منتج تم ذكره.\n"
            f"- استخدم الـ ID مباشرة مع أداة add_to_cart — لا تبحث عنه تاني.\n"
            f"- لا تخترع أي product_id من عقلك أبداً."
        )

    # تعليمات اللغة
    user_lang = state.get("user_language", "ar")
    from services.language_service import get_language_instruction
    lang_instruction = get_language_instruction(user_lang)
    if lang_instruction:
        extra_parts.append(lang_instruction)

    extra_context = "".join(extra_parts)

    # === تشغيل الوكيل مع الأدوات ===
    try:
        response = await run_agent_with_tools(
            system_prompt=CART_AGENT_PROMPT,
            user_message=last_msg,
            tools=CART_TOOLS,
            context=extra_context,
            session_id=session_id,
            user_id=user_id,
            agent_name="cart_agent",
        )
    except Exception as e:
        print(f"❌ Cart agent error: {e}")
        response = "عذراً، حدث خطأ في معالجة طلب السلة."

    return {
        "agent_output": response,
        "current_agent": "cart_agent",
        "messages": [AIMessage(content=response, name="cart_agent")],
    }
