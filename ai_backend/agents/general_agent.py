"""
💬 General Agent — الوكيل العام
بيرد على المحادثات العامة والترحيب
"""
from graph.state import AgentState
from services.gemini_service import get_llm
from prompts.agent_prompts import GENERAL_AGENT_PROMPT
from langchain_core.messages import AIMessage, SystemMessage


async def run_general_agent(state: AgentState) -> dict:
    """تشغيل الوكيل العام — بدون أدوات، رد مباشر."""
    llm = get_llm()
    messages = state.get("messages", [])

    # سياق الذاكرة
    memory_ctx = state.get("memory_context", "")
    user_lang = state.get("user_language", "ar")
    enhanced_prompt = GENERAL_AGENT_PROMPT

    # تعليمات اللغة
    from services.language_service import get_language_instruction
    lang_instruction = get_language_instruction(user_lang)
    if lang_instruction:
        enhanced_prompt += lang_instruction

    if memory_ctx:
        enhanced_prompt += f"\n\n--- سياق المستخدم ---\n{memory_ctx}"

    # تحليل المزاج وتكييف الرد
    sentiment = state.get("sentiment", "neutral")
    if sentiment == "negative":
        enhanced_prompt += "\n\n⚠️ المستخدم يبدو محبط. كن متعاطف وقدم مساعدة إضافية."
    elif sentiment == "excited":
        enhanced_prompt += "\n\n😊 المستخدم متحمس! شاركه الحماس واقترح حاجات مثيرة."

    # رد مباشر بدون أدوات
    full_messages = [SystemMessage(content=enhanced_prompt)] + list(messages)
    response = await llm.ainvoke(full_messages)

    return {
        "agent_output": response.content,
        "current_agent": "general_agent",
        "messages": [AIMessage(content=response.content, name="general_agent")],
    }
