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
    """الحصول على ملخص أداء المنصة (إيرادات، طلبات، كنسلة). استخدمها للأسئلة المالية والكمية."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("key_metrics", {}), ensure_ascii=False)

@tool
async def get_bazaar_rankings(period: str = "month") -> str:
    """الحصول على قائمة أفضل البازارات أداءً وترتيبهم (الإيرادات والطلبات)."""
    data = await compute_platform_analytics(period)
    return json.dumps(data.get("bazaar_rankings", []), ensure_ascii=False)

@tool
async def get_system_health() -> str:
    """الحصول على تقرير الصحة التقنية وجودة البيانات (الصور والوصف والطلبات المعلقة)."""
    data = await get_platform_health()
    return json.dumps(data, ensure_ascii=False)

@tool
async def get_top_products_data(limit: int = 10) -> str:
    """الحصول على المنتجات الأكثر طلباً من قاعدة البيانات (أعلى المنتجات مبيعاً بعدد الطلبات والإيرادات)."""
    from services.aws_db_service import _execute_aurora_query
    from psycopg2.extras import RealDictCursor
    import asyncio
    
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT 
                    p.name_ar as product_name,
                    oi.product_id,
                    COUNT(oi.id) as order_count,
                    SUM(oi.quantity * oi.price_at_purchase)::FLOAT as total_revenue
                FROM order_items oi
                JOIN orders o ON oi.order_id = o.id
                JOIN products p ON oi.product_id = p.id
                WHERE o.status IN ('delivered', 'accepted', 'preparing')
                GROUP BY p.name_ar, oi.product_id
                ORDER BY order_count DESC
                LIMIT %s
            """, (limit,))
            rows = cur.fetchall()
            return [dict(r) for r in rows]
    
    result = await asyncio.to_thread(_execute_aurora_query, _query)
    if not result:
        return "لا توجد بيانات طلبات حالياً في قاعدة البيانات."
    return json.dumps(result, ensure_ascii=False, default=str)

@tool
async def search_technical_docs(query: str) -> str:
    """البحث في قاعدة المعلومات التقنية والإدارية (RAG) للإجابة على أسئلة حول القواعد أو السياسات."""
    from services.gemini_service import get_query_embeddings
    from services.aws_db_service import search_knowledge_base
    
    # 1. Embed query
    embeddings = get_query_embeddings()
    vector = await embeddings.aembed_query(query)
    
    # 2. Search DB
    results = await search_knowledge_base(vector, limit=3)
    
    if not results:
        return "لا توجد معلومات تقنية مسجلة لهذا السؤال."
        
    context = "\n---\n".join([r["text_content"] for r in results])
    return f"معلومات مسترجعة من قاعدة المعرفة:\n{context}"

ADMIN_TOOLS = [get_analytics_summary, get_bazaar_rankings, get_system_health, get_top_products_data, search_technical_docs]

# ============================================================
# Prompts
# ============================================================

ADMIN_SYSTEM_MSG = """أنت "خبير ذكاء الأعمال" (BI Expert) والمساعد التنفيذي لمنصة السياحة المصرية.
شخصيتك: محترفة جداً، تحليلية، وتستخدم لغة بيزنس عربية مصرية راقية.

تعليمات العمليات:
1. الدقة الرياضية: لا تذكر أرقاماً أبداً من وحي خيالك. استخدم الأدوات (Tools) دائماً لجلب البيانات.
2. التحليل النقدي: إذا لاحظت هبوطاً في الإيرادات أو زيادة في الكنسلة، أشر إلى ذلك كـ "تنبيه" واقترح حلاً.
3. التوافق مع قاعدة البيانات: أنت متصل بـ Aurora PostgreSQL وتستخدم تقنيات الـ RAG لجلب القواعد الإدارية.
4. الردود المهيكلة: استخدم Markdown جداول، ونقاط، ومقاطع واضحة.
5. استخدم الأدوات المتاحة: عندما يسأل المدير عن المنتجات الأكثر طلباً، استخدم أداة get_top_products_data. عندما يسأل عن البازارات، استخدم get_bazaar_rankings. عندما يسأل عن الأداء العام، استخدم get_analytics_summary.

يجب أن تكون إجابتك النهائية بصيغة JSON التالية حصراً:
{
    "text": "الإجابة التحليلية هنا بتنسيق Markdown",
    "quick_actions": ["سؤال متابعة مقترح 1", "إصدار تقرير مفصل", "تحليل بازار معين"],
    "sentiment": "positive/neutral/warning"
}
"""

# ============================================================
# Agent Functions
# ============================================================

async def admin_chat(question: str, context: str = "") -> dict:
    """الرد على أدمن باستخدام عميل LangGraph ReAct الذكي المحسن."""
    llm = get_llm(temperature=0.2, app_id="admin") # Low temperature for precision
    
    # PRE-FETCH: Always inject live data context so the LLM has real numbers
    # even if tool calling fails
    try:
        analytics = await compute_platform_analytics("month")
        live_context = json.dumps({
            "key_metrics": analytics.get("key_metrics", {}),
            "bazaar_rankings": analytics.get("bazaar_rankings", [])[:5],
        }, ensure_ascii=False, default=str)
    except Exception:
        live_context = "{}"
    
    agent = create_react_agent(llm, ADMIN_TOOLS, state_modifier=ADMIN_SYSTEM_MSG)
    
    prompt_str = f"""بيانات المنصة الحية (من Aurora PostgreSQL):
{live_context}

سياق إضافي من النظام: {context}

سؤال المدير التنفيذي: {question}"""
    
    try:
        response = await agent.ainvoke({"messages": [HumanMessage(content=prompt_str)]})
        final_text = response["messages"][-1].content
        
        parsed = _parse_json_response(final_text, None)
        if parsed and "text" in parsed:
            return parsed
            
        return {
            "text": final_text,
            "quick_actions": ["أداء المنصة هذا الشهر", "البازارات المتأخرة"],
            "sentiment": "neutral"
        }
    except Exception as e:
        print(f"⚠️ Professional Agent Error: {e}")
        return {
            "text": "نعتذر، حدثت فجوة تقنية في استرجاع البيانات. يتم العمل على الربط حالياً.",
            "quick_actions": [],
            "sentiment": "warning"
        }



# ... Rest of the file (generators) ...


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
    llm = get_llm(temperature=0.5, app_id="admin")
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
    llm = get_llm(temperature=0.6, app_id="admin")
    
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
    
    # Flatten metrics to the root for Flutter UI compatibility (active_bazaars, total_bazaars, etc.)
    metrics = analytics.get("key_metrics", {})
    for key, value in metrics.items():
        parsed[key] = value
        
    return parsed


# ============================================================
# Utility
# ============================================================

def _parse_json_response(text: str, fallback):
    from utils.json_parser import parse_json_response
    parsed = parse_json_response(text)
    return parsed if parsed else fallback
