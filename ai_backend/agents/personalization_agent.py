"""
✨ Personalization Agent — وكيل التخصيص
الوكيل الأذكى — بيحلل مشاعر المستخدم وبيقترح حاجات بدون ما يتسأل
"""
import logging
from graph.state import AgentState
from services.gemini_service import get_llm, get_fast_llm
from langchain_core.messages import AIMessage, SystemMessage
from memory.semantic_memory import get_preferences_context

logger = logging.getLogger(__name__)


PERSONALIZATION_PROMPT = """أنت وكيل التخصيص الذكي في نظام السياحة المصرية. ✨

مهامك الأساسية:
1. 🎭 تحليل مشاعر المستخدم وتكييف الرد
2. 💡 اقتراحات تلقائية ذكية بناءً على السياق
3. 🧠 تعلم تفضيلات المستخدم

=== تحليل المشاعر ===
اكتشف مزاج المستخدم وتكيف معاه:

| المزاج | العلامات | كيف تتكيف |
|--------|----------|-----------|
| 😊 متحمس | "واو", "حلو", "عظيم" | زوّد الحماس واقترح أكتر |
| 😐 محايد | "طيب", "ماشي" | كن مختصر ومفيد |  
| 😤 محبط | "مفيش", "تاني", "مش عاجبني" | اعتذر وقدم بدائل مختلفة |
| 🤔 محتار | "مش عارف", "ايه الأحسن" | اسأل أسئلة توضيحية |
| 🤩 فضولي | "قولي أكتر", "ازاي" | وسّع المعلومات وأكتر تفاصيل |

=== اقتراحات تلقائية ===
بناءً على المحادثة، اقترح حاجات مفيدة:
- بعد ذكر منتج → اقترح منتج مكمل
- بعد سؤال تاريخي → اقترح منتج متعلق
- بعد إضافة للسلة → اقترح كوبون أو منتج مكمل
- لو المستخدم جديد → رحب وقدم العروض

أجب بالعربية بلهجة مصرية ودية. 😊"""


async def run_personalization_agent(state: AgentState) -> dict:
    """تشغيل وكيل التخصيص — تحليل مشاعر + اقتراحات تلقائية."""
    llm = get_llm(temperature=0.5)
    messages = state.get("messages", [])
    last_message = messages[-1].content if messages else ""

    # تحميل سياق التفضيلات
    prefs_ctx = ""
    prefs = state.get("user_preferences", {})
    if prefs:
        from models.memory import UserPreferences
        user_prefs = UserPreferences(**prefs) if isinstance(prefs, dict) else UserPreferences()
        prefs_ctx = get_preferences_context(user_prefs)

    # سياق المحادثة
    memory_ctx = state.get("memory_context", "")

    # === تحليل المشاعر (بدون LLM) ===
    sentiment = await analyze_sentiment_quick(last_message)

    # === تكييف الرد ===
    enhanced_prompt = PERSONALIZATION_PROMPT
    if prefs_ctx:
        enhanced_prompt += f"\n\n{prefs_ctx}"
    if memory_ctx:
        enhanced_prompt += f"\n\n{memory_ctx}"

    chat_history = state.get("chat_history", [])
    full_messages = [SystemMessage(content=enhanced_prompt)] + chat_history[-10:] + list(messages)
    
    import asyncio
    # تشغيل توليد الرد وتوليد الاقتراحات بالتوازي لتسريع الاستجابة
    fast_llm = get_fast_llm(temperature=0.7)
    response_task = llm.ainvoke(full_messages)
    suggestions_task = _generate_suggestions(fast_llm, last_message, prefs_ctx, memory_ctx)

    response, suggestions = await asyncio.gather(response_task, suggestions_task)

    return {
        "agent_output": response.content,
        "current_agent": "personalization_agent",
        "sentiment": sentiment,
        "proactive_suggestions": suggestions,
        "messages": [AIMessage(content=response.content, name="personalization_agent")],
    }



async def _generate_suggestions(llm, message: str, prefs_ctx: str,
                                 memory_ctx: str) -> list[dict]:
    """توليد اقتراحات تلقائية ذكية."""
    if not message:
        return []

    prompt = f"""بناءً على رسالة المستخدم والسياق، اقترح 1-2 اقتراحات مفيدة.

رسالة المستخدم: "{message}"
{prefs_ctx}
{memory_ctx}

أعطِ اقتراحات ذكية ومنطقية. لكل اقتراح أعد سطر بهذا التنسيق:
TYPE|TITLE|MESSAGE

أنواع الاقتراحات: product, history, bazaar, tip
مثال:
product|بردية مرسومة يدوياً|هل تعلم إن البردية بتكمل التمثال كهدية؟ 🎁
tip|نصيحة تسوق|أفضل وقت للزيارة الصبح — أقل زحمة وأسعار أحسن 😉

أعد الاقتراحات فقط بدون شرح. لو مفيش اقتراح مناسب أعد: NONE"""

    try:
        response = await llm.ainvoke(prompt)
        text = response.content.strip()

        if text == "NONE" or not text:
            return []

        suggestions = []
        for line in text.split("\n"):
            parts = line.strip().split("|")
            if len(parts) == 3:
                suggestions.append({
                    "type": parts[0].strip(),
                    "title": parts[1].strip(),
                    "message": parts[2].strip(),
                })

        return suggestions[:2]  # أقصى 2 اقتراحات
    except Exception:
        return []


async def analyze_sentiment_quick(message: str) -> str:
    """تحليل فوري للمشاعر بالكلمات المفتاحية — بدون LLM."""
    if not message:
        return "neutral"
    msg = message.lower()

    # كلمات مفتاحية لكل مزاج
    sentiments = {
        "excited": ["واو", "رائع", "حلو", "جميل", "عظيم", "ممتاز", "أحسن", "wow", "amazing", "❤", "😍", "🤩"],
        "positive": ["شكراً", "تمام", "احسنت", "حبيت", "كويس", "thanks", "good", "great", "😊", "👍"],
        "negative": ["وحش", "مش كويس", "زفت", "بطيء", "مفيش", "زهقت", "مش عاجبني", "bad", "slow", "😡", "😤"],
        "curious": ["ايه", "مين", "ازاي", "ليه", "فين", "امتى", "قولي", "احكيلي", "عايز اعرف", "?", "؟"],
        "confused": ["مش فاهم", "مش عارف", "محتار", "ايه الفرق", "confused"],
    }

    for sentiment, keywords in sentiments.items():
        if any(kw in msg for kw in keywords):
            return sentiment
    return "neutral"
