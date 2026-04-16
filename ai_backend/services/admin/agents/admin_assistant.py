"""
🤖 Admin Assistant Agent — ReAct Agent for Admin Panel.
Uses tools securely to query analytics.
"""
from datetime import datetime
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import HumanMessage

from core.llm_service import get_llm, get_fast_llm
from core.analytics_service import compute_platform_analytics, get_platform_health
from core.json_utils import parse_json_response
import json

import logging
logger = logging.getLogger(__name__)

# ============================================================
# Tools
# ============================================================

@tool
async def get_analytics_summary(period: str = "month") -> str:
    """Get platform performance summary (revenue, orders, active bazaars). Use ONLY when asked about numbers."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("key_metrics", {}), ensure_ascii=False)


@tool
async def get_bazaar_rankings(period: str = "month") -> str:
    """Get top performing bazaars rankings."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("bazaar_rankings", []), ensure_ascii=False)


@tool
async def get_system_health() -> str:
    """Check platform system health, active products, and bazaars."""
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
2. لا تخترع (Hallucinate) أي أرقام من عقلك. إذا لم تجد بيانات واضحة أجب بـ "لا توجد بيانات حالياً".
3. أجب دائماً بتنسيق Markdown احترافي، واستخدم العربية بشكل مهني وودي.
4. اطرح مقترحات عملية بناءً على الأرقام واكتبها في نهاية ردك بشكل نقاط.
5. لا تقم أبداً بالرد بصيغة JSON، فقط أجب باللغة العربية مباشرة والتنسيق.
"""

# ============================================================
# Agent Execution
# ============================================================

async def admin_chat(question: str, context: str = "") -> dict:
    """Execute LangGraph ReAct agent for the admin chat."""
    llm = get_llm(temperature=0.3, app_id="admin")
    agent = create_react_agent(llm, ADMIN_TOOLS, state_modifier=ADMIN_SYSTEM_MSG)
    
    prompt_str = f"سياق إضافي: {context}\n\nسؤال المدير: {question}"
    
    try:
        response = await agent.ainvoke({"messages": [HumanMessage(content=prompt_str)]})
        final_text = response["messages"][-1].content
        
        parsed = parse_json_response(final_text)
        if parsed and "text" in parsed:
             return parsed
             
        return {
             "text": final_text,
             "quick_actions": ["أداء المنصة هذا الشهر", "البازارات المتأخرة"],
        }
    except Exception as e:
        logger.error(f"ReAct Agent Error: {e}")
        return {
            "text": "عذراً، حدثت مشكلة أثناء معالجة طلبك.",
            "quick_actions": [],
        }

# ============================================================
# Direct Generators (Promotions, Reports, Messages)
# ============================================================

async def generate_business_report(period: str = "month", focus: str = None) -> dict:
    """Generate comprehensive BI report using Fast LLM."""
    llm = get_llm(temperature=0.5, app_id="admin")
    analytics = await compute_platform_analytics(period)

    focus_instruction = ""
    if focus:
        focus_map = {
            "revenue": "ركز على تحليل وتوجهات الإيرادات",
            "bazaars": "ركز على أداء ونشاط البازارات وتوزيع التقييمات",
            "products": "ركز على المنتجات النشطة والفئات الأكثر طلباً",
            "customers": "ركز على توزيع العملاء وسلوك الحجوزات",
        }
        focus_instruction = focus_map.get(focus, "")

    safe_data = {
        "metrics": analytics.get("key_metrics"),
        "bazaars": analytics.get("bazaar_rankings", [])[:5]
    }

    prompt = f"""أنت محلل أعمال محترف في منصة سياحة مصرية.

بيانات الأداء للفترة ({period}):
{json.dumps(safe_data, ensure_ascii=False, default=str)}

المطلوب: تقرير ذكي شامل {focus_instruction}

اكتب التقرير بصيغة JSON:
{{
    "executive_summary": "ملخص تنفيذي (3-4 جمل) بأهم النتائج والاتجاهات",
    "insights": [
        {{"type": "success|warning|tip|danger", "icon": "📈", "title": "عنوان", "text": "تفصيل"}}
    ],
    "trends": [
        {{"metric": "المقياس", "direction": "up|down|flat", "value": "القيمة", "analysis": "التحليل"}}
    ],
    "recommendations": [
        "توصية عملية 1",
        "توصية عملية 2"
    ],
    "anomalies": []
}}"""

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    if not parsed:
         parsed = {
            "executive_summary": "تعذر توليد التقرير التلقائي.",
            "insights": [], "trends": [], "recommendations": [], "anomalies": []
         }

    parsed["period"] = period
    parsed["key_metrics"] = analytics.get("key_metrics", {})
    parsed["bazaar_rankings"] = analytics.get("bazaar_rankings", [])
    parsed["charts_data"] = analytics.get("charts_data", {})

    return parsed


async def get_platform_insights() -> dict:
    """Get fast snapshot insights of the platform."""
    llm = get_fast_llm(temperature=0.4, app_id="admin")
    try:
        analytics = await compute_platform_analytics("week")
        health = await get_platform_health()
    except Exception as e:
        logger.error(f"Error getting platform insights data: {e}")
        return {"health_score": 0, "insights": [], "alerts": [{"type":"danger", "icon":"🔴", "title":"Error", "text": str(e)}], "quick_stats": {}}

    safe_data = {
        "metrics": analytics.get("key_metrics"),
        "health": health
    }

    prompt = f"""حلل بيانات المنصة واستخرج insights سريعة بصيغة JSON:
{json.dumps(safe_data, ensure_ascii=False)}

المخرجات المطلوبة JSON:
{{"insights": [{{"type": "tip", "title": "...", "text": "...", "icon": "💡"}}], "alerts": [], "bazaar_tiers": {{"gold": 0, "silver": 0, "bronze": 0}}}}"""

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    if not parsed:
        parsed = {"insights": [], "alerts": [], "bazaar_tiers": {}}

    parsed["health_score"] = health.get("health_score", 0)
    parsed["quick_stats"] = analytics.get("key_metrics", {})
    
    return parsed


async def generate_admin_message(message_type: str, bazaar_name: str, context: str = "", custom_notes: str = "") -> dict:
    """Generate communication message for bazaars."""
    llm = get_llm(temperature=0.6, app_id="admin")
    
    prompt = f"""أنت مسؤول تواصل محترف في منصة سياحة مصرية.
النوع: {message_type}
البازار الموجه له: {bazaar_name}
ملاحظات إضافية: {custom_notes}
السياق: {context}

اكتب الخطاب بصيغة JSON:
{{"subject": "عنوان احترافي", "body": "نص الخطاب", "tone": "professional", "variations": [{{"body": "نسخة أخرى بصيغة أقصر"}}]}}"""

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    return parsed if parsed else {"subject": "إشعار إداري", "body": "حدث خطأ في توليد الرسالة.", "tone": "professional", "variations": []}


async def suggest_promotions() -> dict:
    """Generate promotional suggestions for admin to run platform-wide marketing."""
    llm = get_fast_llm(temperature=0.7, app_id="admin")
    prompt = f"""أنت خبير تسويق في منصة سياحة مصرية.
التاريخ: {datetime.now().strftime("%Y-%m-%d")}

اقترح عروض ترويجية ذكية للمنصة لدعم المبيعات وجذب السياح بصيغة JSON:
{{"suggestions": [{{"type": "discount|bundle|coupon", "title": "اسم العرض", "description": "الوصف", "priority": "high|medium|low", "estimated_impact": "مثال: زيادة 10% بالمبيعات"}}], "seasonal_events": [{{"name": "...", "date": "..."}}], "market_analysis": "تحليل مختصر"}}"""

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    return parsed if parsed else {"suggestions": [], "seasonal_events": [], "market_analysis": ""}
