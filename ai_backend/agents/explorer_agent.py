"""
🏛️ Explorer Agent — وكيل الاستكشاف الموحد
يجمع بين البحث في التاريخ والآثار (History) والإرشاد السياحي للأماكن (Tour Guide)
يستخدم RAG + Tool Calling للبحث المجمّع السريع
"""
import logging
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import EXPLORER_AGENT_PROMPT
from tools.all_tools import ARTIFACT_TOOLS, BAZAAR_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage
from rag.engine import search_knowledge

# دمج أدوات الآثار وأماكن البازارات
EXPLORER_TOOLS = ARTIFACT_TOOLS + BAZAAR_TOOLS

logger = logging.getLogger(__name__)

async def run_explorer_agent(state: AgentState) -> dict:
    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""
    chat_history = state.get("chat_history", [])

    extra_parts = []

    # بحث RAG للاثنين معاً (آثار + بازارات مصرية)
    try:
        rag_context = await asyncio.wait_for(
            search_knowledge(f"تاريخ سياحة آثار مصر {last_msg}"),
            timeout=15.0,
        )
        if rag_context:
            extra_parts.append(f"\n\n--- قاعدة المعرفة (تاريخ وسياحة) ---\n{rag_context}")
    except Exception as e:
        logger.warning(f"Explorer RAG timeout or error: {e}")

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
    
    try:
        response = await run_agent_with_tools(
            system_prompt=EXPLORER_AGENT_PROMPT,
            user_message=last_msg,
            tools=EXPLORER_TOOLS,
            context=extra_context,
            chat_history=chat_history,
            session_id=session_id,
            agent_name="explorer_agent",
        )
    except Exception as e:
        logger.error(f"Explorer agent error: {e}")
        response = "عذراً، حدث خطأ أثناء البحث عن المعلومات التاريخية والسياحية."

    return {
        "agent_output": response,
        "current_agent": "explorer_agent",
        "messages": [AIMessage(content=response, name="explorer_agent")],
    }
