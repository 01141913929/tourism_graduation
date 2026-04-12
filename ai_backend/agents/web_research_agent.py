"""
🌐 Web Research Agent — وكيل البحث في الإنترنت
باحث متخصص في التاريخ المصري والسياحة
✅ يستخدم Tool Calling مع Tavily Web Tools
"""
import asyncio
from graph.state import AgentState

from prompts.agent_prompts import WEB_RESEARCH_PROMPT
from tools.web_tools import WEB_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage


async def run_web_research_agent(state: AgentState) -> dict:
    """تشغيل وكيل البحث في الويب — Tool Calling مع Tavily."""

    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""

    session_id = state.get("session_id", "default")

    # === تشغيل الوكيل مع أدوات البحث ===
    try:
        response = await run_agent_with_tools(
            system_prompt=WEB_RESEARCH_PROMPT,
            user_message=last_msg,
            tools=WEB_TOOLS,
            timeout=45.0,  # وقت أطول للبحث في الويب
            session_id=session_id,
            agent_name="web_research_agent",
        )
    except Exception as e:
        print(f"❌ Web research error: {e}")
        response = "عذراً، لم أتمكن من البحث في الإنترنت."

    return {
        "agent_output": response,
        "current_agent": "web_research_agent",
        "messages": [AIMessage(content=response, name="web_research_agent")],
    }
