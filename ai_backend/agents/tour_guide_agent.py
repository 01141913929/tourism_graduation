"""
🗺️ Tour Guide Agent — وكيل المرشد السياحي
مرشد سياحي مصري خبير ومحب لبلده
✅ يستخدم RAG + Tool Calling للبازارات والأماكن
"""
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import TOUR_GUIDE_PROMPT
from tools.all_tools import BAZAAR_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage
from rag.engine import search_knowledge


async def run_tour_guide_agent(state: AgentState) -> dict:
    """تشغيل وكيل المرشد السياحي — RAG + Tool Calling للبازارات."""

    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""

    # === بناء السياق الإضافي ===
    extra_parts = []

    # بحث RAG
    try:
        rag_context = await asyncio.wait_for(
            search_knowledge(f"سياحة مصر {last_msg}"),
            timeout=15.0,
        )
        if rag_context:
            extra_parts.append(f"\n\n--- معلومات من قاعدة المعرفة ---\n{rag_context}")
    except asyncio.TimeoutError:
        print("⚠️ Tour RAG timeout")
    except Exception as e:
        print(f"⚠️ Tour RAG error: {e}")

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

    extra_context = "".join(extra_parts)

    session_id = state.get("session_id", "default")

    # === تشغيل الوكيل مع أدوات البازارات ===
    try:
        response = await run_agent_with_tools(
            system_prompt=TOUR_GUIDE_PROMPT,
            user_message=last_msg,
            tools=BAZAAR_TOOLS,
            context=extra_context,
            session_id=session_id,
            agent_name="tour_guide_agent",
        )
    except Exception as e:
        print(f"❌ Tour guide error: {e}")
        response = "عذراً، حدث خطأ. جرب تاني!"

    return {
        "agent_output": response,
        "current_agent": "tour_guide_agent",
        "messages": [AIMessage(content=response, name="tour_guide_agent")],
    }
