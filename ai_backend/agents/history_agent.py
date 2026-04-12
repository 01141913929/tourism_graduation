"""
📜 History Agent — وكيل التاريخ والآثار
مؤرخ خبير بالحضارة المصرية القديمة
✅ يستخدم RAG + Tool Calling للبحث في الآثار من Firestore
"""
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import HISTORY_AGENT_PROMPT
from tools.all_tools import ARTIFACT_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage
from rag.engine import search_knowledge


async def run_history_agent(state: AgentState) -> dict:
    """تشغيل وكيل التاريخ — RAG أولاً ثم Tool Calling للآثار."""

    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""

    # === بناء السياق الإضافي ===
    extra_parts = []

    # بحث RAG أولاً
    try:
        rag_context = await asyncio.wait_for(
            search_knowledge(last_msg),
            timeout=15.0,
        )
        if rag_context:
            extra_parts.append(f"\n\n--- معلومات من قاعدة المعرفة ---\n{rag_context}")
    except asyncio.TimeoutError:
        print("⚠️ RAG search timeout — continuing without RAG")
    except Exception as e:
        print(f"⚠️ RAG error: {e}")

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
    
    # === تشغيل الوكيل مع أدوات الآثار ===
    try:
        response = await run_agent_with_tools(
            system_prompt=HISTORY_AGENT_PROMPT,
            user_message=last_msg,
            tools=ARTIFACT_TOOLS,
            context=extra_context,
            session_id=session_id,
            agent_name="history_agent",
        )
    except Exception as e:
        print(f"❌ History agent error: {e}")
        response = "عذراً، حدث خطأ أثناء البحث عن المعلومات التاريخية."

    return {
        "agent_output": response,
        "current_agent": "history_agent",
        "messages": [AIMessage(content=response, name="history_agent")],
    }
