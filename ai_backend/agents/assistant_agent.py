"""
🧠 Assistant Agent — المساعد العام الذكي
يجمع بين البحث في الإنترنت (Web Research) وإجابات الترحيب العامة (General Agent)
✅ يدعم Tavily Tools بشكل اختياري حسب سؤاله 
"""
from graph.state import AgentState
from prompts.agent_prompts import ASSISTANT_AGENT_PROMPT
from tools.web_tools import WEB_TOOLS
from agents.tool_executor import run_agent_with_tools
from langchain_core.messages import AIMessage

async def run_assistant_agent(state: AgentState) -> dict:
    messages = state.get("messages", [])
    last_msg = messages[-1].content if messages else ""
    chat_history = state.get("chat_history", [])

    session_id = state.get("session_id", "default")
    user_lang = state.get("user_language", "ar")
    memory_ctx = state.get("memory_context", "")
    sentiment = state.get("sentiment", "neutral")

    # تجميع السياق
    extra_parts = []
    
    from services.language_service import get_language_instruction
    lang_instruction = get_language_instruction(user_lang)
    if lang_instruction:
        extra_parts.append(lang_instruction)

    if memory_ctx:
        extra_parts.append(f"\n\n--- سياق المستخدم ---\n{memory_ctx}")

    if sentiment == "negative":
        extra_parts.append("\n\n⚠️ المستخدم يبدو محبط. كن متعاطف وقدم مساعدة إضافية.")
    elif sentiment == "excited":
        extra_parts.append("\n\n😊 المستخدم متحمس! شاركه الحماس واقترح حاجات مثيرة.")

    extra_context = "".join(extra_parts)

    try:
        response = await run_agent_with_tools(
            system_prompt=ASSISTANT_AGENT_PROMPT,
            user_message=last_msg,
            tools=WEB_TOOLS,
            timeout=40.0,
            context=extra_context,
            chat_history=chat_history,
            session_id=session_id,
            agent_name="assistant_agent",
        )
    except Exception as e:
        print(f"❌ Assistant agent error: {e}")
        response = "عذراً، لم أتمكن من الرد عليك في الوقت الحالي."

    return {
        "agent_output": response,
        "current_agent": "assistant_agent",
        "messages": [AIMessage(content=response, name="assistant_agent")],
    }
