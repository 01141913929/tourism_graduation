"""
🤖 Admin Assistant Agent — المساعد الإداري الذكي (LangGraph ReAct)
يجاوب على أسئلة الأدمن بذكاء، ويستخدم أدوات لجلب البيانات فقط عند الحاجة لتجنب اختناق الذاكرة.
"""
import json
from datetime import datetime
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import HumanMessage
from services.gemini_service import get_llm, get_fast_llm
from services.analytics_service import compute_platform_analytics, get_platform_health

# ============================================================
# الأدوات (Tools) — تجنب الـ Prompt Overload
# ============================================================

@tool
async def get_analytics_summary(period: str = "month") -> str:
    """الحصول على ملخص أداء المنصة (الإيرادات، الطلبات، الكنسلة، العملاء المالكين). لا تستدعيها إلا إذا سأل المستخدم عن أرقام أداء."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("key_metrics", {}), ensure_ascii=False)

@tool
async def get_bazaar_rankings(period: str = "month") -> str:
    """الحصول على قائمة أفضل البازارات أداءً وترتيبهم (الإيرادات والطلبات)."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("bazaar_rankings", []), ensure_ascii=False)

@tool
async def get_system_health() -> str:
    """أداة لفحص صحة المنصة التقنية وعدد المنتجات النشطة والمنتجات التي تحتاج صور."""
    data = await get_platform_health()
    return json.dumps(data, ensure_ascii=False)

ADMIN_TOOLS = [get_analytics_summary, get_bazaar_rankings, get_system_health]

# ============================================================
# Prompts
# ============================================================

ADMIN_SYSTEM_MSG = """أنت المساعد الإداري الذكي لمنصة السياحة المصرية.
مهمتك الرد على أسئلة مدير المنصة بدقة عالية جداً.

تعليمات صارمة:
1. أنت تملك أدوات (Tools) لاسترجاع البيانات لحظياً. استخدمها دائماً قبل الإجابة على أي سؤال يخص الإيرادات، البازارات، أو صحة النظام.
2. لا تخترع (Hallucinate) أي مبيعات أو أرقام من عقلك، إذا لم تجد بيانات واضحة أجب بـ "لا توجد بيانات حالياً".
3. أجب دائماً بتنسيق Markdown احترافي، واستخدم العربية المصرية بشكل مهني وودي.
4. اطرح مقترحات عملية بناءً على الأرقام التي تسترجعها.

يجب أن تكون إجابتك النهائية بصيغة JSON التالية حصراً:
{
    "text": "الإجابة هنا بتنسيق ماركداون (لا تستخدم markdown code blocks حول الـ JSON أرجوك)",
    "quick_actions": ["سؤال متابعة مقترح 1", "سؤال متابعة مقترح 2"]
}
"""

# ============================================================
# Agent Functions
# ============================================================

async def admin_chat(question: str, context: str = "") -> dict:
    """الرد على أدمن باستخدام عميل LangGraph ReAct الذكي."""
    llm = get_llm(temperature=0.3)
    agent = create_react_agent(llm, ADMIN_TOOLS, state_modifier=ADMIN_SYSTEM_MSG)
    
    prompt_str = f"سياق إضافي: {context}\n\nسؤال المدير: {question}"
    
    try:
        response = await agent.ainvoke({"messages": [HumanMessage(content=prompt_str)]})
        final_text = response["messages"][-1].content
        
        parsed = _parse_json_response(final_text, None)
        if parsed and "text" in parsed:
            return parsed
            
        return {
            "text": final_text,
            "quick_actions": ["أداء المنصة هذا الشهر", "البازارات المتأخرة"],
            "charts_data": None,
            "data_tables": None,
        }
    except Exception as e:
        print(f"⚠️ ReAct Agent Error: {e}")
        return {
            "text": "عذراً، حدثت مشكلة أثناء استرجاع البيانات. حاول مرة أخرى.",
            "quick_actions": [],
            "charts_data": None,
            "data_tables": None,
        }


# ============================================================
# Other Specific Generators
# ============================================================

BUSINESS_REPORT_PROMPT = """أنت محلل أعمال محترف في منصة سياحة مصرية.

بيانات الأداء للفترة ({period}):
{analytics_data}

المطلوب: تقرير ذكي شامل {focus_instruction}

اكتب التقرير بصيغة JSON:
{{
    "executive_summary": "ملخص تنفيذي (3-4 جمل) بأهم النتائج والاتجاهات",
    "insights": [
        {{"type": "success/warning/tip/danger", "icon": "📈", "title": "عنوان", "text": "تفصيل"}}
    ],
    "trends": [
        {{"metric": "المقياس", "direction": "up/down/flat", "value": "القيمة", "analysis": "التحليل"}}
    ],
    "recommendations": [
        "توصية عملية 1",
        "توصية عملية 2"
    ],
    "anomalies": []
}}
"""

async def generate_business_report(period: str = "month", focus: str = None) -> dict:
    llm = get_llm(temperature=0.5)
    analytics = await compute_platform_analytics(period)

    focus_instruction = ""
    if focus:
        focus_map = {
            "revenue": "ركز على الإيرادات",
            "bazaars": "ركز على البازارات",
            "products": "ركز على المنتجات",
        }
        focus_instruction = focus_map.get(focus, "")

    # We only inject metrics and rankings to avoid huge context
    safe_data = {
        "metrics": analytics.get("key_metrics"),
        "bazaars": analytics.get("bazaar_rankings", [])[:5]
    }

    prompt = BUSINESS_REPORT_PROMPT.format(
        period=period,
        analytics_data=json.dumps(safe_data, ensure_ascii=False, default=str),
        focus_instruction=focus_instruction,
    )

    result = await llm.ainvoke(prompt)
    parsed = _parse_json_response(result.content, {
        "executive_summary": "لم يتم توليد التقرير",
        "insights": [],
        "trends": [],
        "recommendations": [],
        "anomalies": [],
    })

    parsed["period"] = period
    parsed["key_metrics"] = analytics.get("key_metrics", {})
    parsed["bazaar_rankings"] = analytics.get("bazaar_rankings", [])
    parsed["charts_data"] = analytics.get("charts_data", {})

    return parsed


async def generate_admin_message(message_type: str, bazaar_name: str, context: str = "", custom_notes: str = "") -> dict:
    llm = get_llm(temperature=0.6)
    
    prompt = f"""أنت مسؤول تواصل محترف في منصة سياحة مصرية.
اكتب رسالة {message_type} لبازار "{bazaar_name}".
ملاحظات: {custom_notes}

اكتب بصيغة JSON:
{{"subject": "عنوان", "body": "نص", "tone": "professional", "variations": []}}"""

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "subject": "رسالة إدارية",
        "body": "مرحباً",
        "tone": "professional",
        "variations": [],
    })


async def suggest_promotions() -> dict:
    llm = get_fast_llm(temperature=0.7)
    prompt = f"""أنت خبير تسويق في منصة سياحة مصرية.
التاريخ: {datetime.now().strftime("%Y-%m-%d")}

اقترح عروض ذكية بصيغة JSON:
{{"suggestions": [], "seasonal_events": [], "market_analysis": ""}}"""

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "suggestions": [],
        "seasonal_events": [],
        "market_analysis": "",
    })


async def get_platform_insights() -> dict:
    llm = get_fast_llm(temperature=0.4)
    try:
        analytics = await compute_platform_analytics("week")
        health = await get_platform_health()
    except Exception as e:
        return {"health_score": 0, "insights": [{"type": "danger", "icon": "🔴", "title": "خطأ", "text": str(e)}], "alerts": []}

    safe_data = {
        "metrics": analytics.get("key_metrics"),
        "health": health
    }

    prompt = f"""حلل هذه البيانات واستخرج insights بصيغة JSON:
{json.dumps(safe_data, ensure_ascii=False)}

الصيغة المطلوبة: {{"insights": [], "alerts": [], "bazaar_tiers": {{}}}}"""

    result = await llm.ainvoke(prompt)
    parsed = _parse_json_response(result.content, {"insights": [], "alerts": [], "bazaar_tiers": {}})
    
    parsed["health_score"] = health.get("health_score", 0)
    parsed["quick_stats"] = analytics.get("key_metrics", {})
    return parsed


# ============================================================
# Utility
# ============================================================

def _parse_json_response(text: str, fallback):
    from utils.json_parser import parse_json_response
    parsed = parse_json_response(text)
    return parsed if parsed else fallback
