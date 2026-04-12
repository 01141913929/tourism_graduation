"""
📝 Conversation Summarizer — تلخيص المحادثات الطويلة
يلخّص المحادثة بعد 15 رسالة عشان context window ما يتملاش
"""
import asyncio
from services.gemini_service import get_llm


SUMMARIZE_PROMPT = """لخّص هذه المحادثة في 3-4 سطور بالعربية.
ركّز على: الموضوعات المطروحة، اهتمامات المستخدم، وأي طلبات محددة.

المحادثة:
{conversation}

الملخص:"""


async def summarize_conversation(messages) -> str:
    """تلخيص المحادثة في فقرة قصيرة.

    يقبل:
    - list من LangChain messages
    - string نص المحادثة مباشرة
    """
    if not messages:
        return ""

    # لو النص جاهز كـ string
    if isinstance(messages, str):
        conversation_text = messages
    else:
        # لو list من الرسائل — نحولها لنص
        if len(messages) < 5:
            return ""
        conversation_text = ""
        for msg in messages[-20:]:  # آخر 20 رسالة فقط
            role = "المستخدم" if hasattr(msg, "type") and msg.type == "human" else "المساعد"
            content = msg.content[:200] if hasattr(msg, "content") else str(msg)[:200]
            conversation_text += f"{role}: {content}\n"

    if not conversation_text.strip():
        return ""

    try:
        llm = get_llm(temperature=0.0)
        prompt = SUMMARIZE_PROMPT.format(conversation=conversation_text)
        result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=15.0)
        return result.content.strip()
    except Exception as e:
        print(f"⚠️ Summarization error: {e}")
        return ""


def should_summarize(message_count: int) -> bool:
    """هل الوقت مناسب لتلخيص المحادثة؟ كل 15 رسالة."""
    return message_count > 0 and message_count % 15 == 0
