"""
🧠 Owner Assistant Agent — المستشار الذكي لأصحاب البازارات
يساعد في: توليد أوصاف، اقتراح أسعار، ردود ذكية، محتوى تسويقي، ملخصات يومية
"""
import json
from datetime import datetime
from services.gemini_service import get_llm, get_fast_llm


# ============================================================
# System Prompts
# ============================================================

PRODUCT_DESCRIPTION_PROMPT = """أنت كاتب محتوى محترف متخصص في المنتجات المصرية التراثية والهدايا التذكارية.

مهمتك: كتابة وصف منتج احترافي يجذب السياح للشراء.

معلومات المنتج:
- الاسم: {product_name}
- الفئة: {category}
- المادة: {material}
- تفاصيل إضافية: {extra_details}

معلومات السوق:
{market_context}

أكتب الرد بصيغة JSON فقط:
{{
    "description_ar": "وصف عربي احترافي (3-5 جمل) يبرز القيمة التراثية والجمالية",
    "description_en": "English translation of the Arabic description",
    "title_suggestions_ar": ["عنوان 1", "عنوان 2", "عنوان 3"],
    "title_suggestions_en": ["Title 1", "Title 2", "Title 3"],
    "category_suggestion": "التصنيف المقترح",
    "category_confidence": 0.95,
    "seo_keywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"],
    "marketing_highlights": ["ميزة 1", "ميزة 2", "ميزة 3"]
}}

اجعل الوصف:
- يتحدث عن القصة وراء المنتج (الحرفة، التاريخ، الرمزية)
- يبرز ما يميزه عن البدائل
- يخاطب السياح والمهتمين بالثقافة المصرية
- مختصر ومؤثر — ليس طويل ممل
"""

PRICE_SUGGESTION_PROMPT = """أنت خبير تسعير متخصص في المنتجات المصرية التراثية.

المنتج: {product_name}
الفئة: {category}
المادة: {material}

بيانات السوق الحالية:
{market_data}

أعطني اقتراح سعر بصيغة JSON:
{{
    "suggested_price": السعر_المقترح,
    "price_range_min": الحد_الأدنى,
    "price_range_max": الحد_الأقصى,
    "market_average": المتوسط,
    "reasoning": "شرح مختصر لسبب هذا السعر",
    "confidence": 0.85
}}

ضع في اعتبارك:
- متوسط السوق في المنصة
- نوع المادة وجودتها
- الطلب على هذه الفئة
- هامش ربح معقول (20-40%)
"""

REPLY_SUGGESTIONS_PROMPT = """أنت مساعد تواصل ذكي لأصحاب البازارات المصرية.

رسالة العميل: "{customer_message}"
اسم العميل: {customer_name}
سياق إضافي: {context}

حلل الرسالة وأعطني ردود مقترحة بصيغة JSON:
{{
    "detected_intent": "نوع السؤال (price_inquiry / availability / shipping / complaint / general)",
    "customer_sentiment": "positive / neutral / negative",
    "language_detected": "ar / en",
    "priority": "high / normal / low",
    "replies": [
        {{"text": "الرد المقترح 1 — مباشر وودي", "tone": "friendly", "confidence": 0.9}},
        {{"text": "الرد المقترح 2 — رسمي ومهني", "tone": "professional", "confidence": 0.85}},
        {{"text": "الرد المقترح 3 — شخصي ومرح", "tone": "casual", "confidence": 0.8}}
    ]
}}

قواعد:
- الردود تكون بنفس لغة العميل
- إذا العميل زعلان → رد يهدّيه ويحل مشكلته
- إذا سأل عن سعر/توفر → رد يشجعه على الشراء
- اجعل الردود مختصرة ومباشرة (جملتين-3 جمل)
- استخدم لهجة مصرية ودية مع إيموجي معتدل
"""

CONTENT_GENERATION_PROMPT = """أنت كاتب محتوى تسويقي محترف للمنتجات المصرية.

نوع المحتوى: {content_type}
المنتج: {product_name}
البازار: {bazaar_name}
تفاصيل العرض: {offer_details}
الجمهور المستهدف: {target_audience}
اللغة: {language}

اكتب المحتوى بصيغة JSON:
{{
    "content": "المحتوى الرئيسي",
    "hashtags": ["#هاشتاق1", "#هاشتاق2"],
    "call_to_action": "جملة تشجع على الإجراء",
    "variations": ["نسخة بديلة 1", "نسخة بديلة 2"]
}}

أنواع المحتوى:
- ad: إعلان قصير جذاب
- social: بوست لسوشيال ميديا (إنستجرام/فيسبوك)
- seo: نص محسّن لمحركات البحث
- offer: إعلان عرض/خصم
"""

DAILY_DIGEST_PROMPT = """أنت مستشار أعمال ذكي لأصحاب البازارات المصرية.

بيانات الأداء:
{analytics_data}

تاريخ اليوم: {today}

اكتب ملخص يومي ذكي بصيغة JSON:
{{
    "greeting": "تحية صباحية مخصصة حسب الأداء",
    "yesterday_summary": {{
        "revenue": المبلغ,
        "orders": العدد,
        "top_product": "اسم أفضل منتج",
        "highlight": "أبرز حدث أمس"
    }},
    "today_goals": [
        "هدف 1 عملي ومحدد",
        "هدف 2",
        "هدف 3"
    ],
    "alerts": [
        {{"type": "warning", "icon": "⚠️", "title": "تنبيه", "text": "نص التنبيه"}},
        {{"type": "tip", "icon": "💡", "title": "نصيحة", "text": "نص النصيحة"}}
    ],
    "tip_of_day": "نصيحة عملية مبنية على البيانات",
    "performance_score": درجة_من_100
}}

كن مختصراً وعملياً. التحية بالعربية المصرية.
ركز على أرقام حقيقية من البيانات (لا تخترع أرقام).
"""

PRODUCT_SUGGESTIONS_PROMPT = """أنت مستشار منتجات خبير في السوق المصري السياحي.

منتجات البازار الحالية:
{current_products}

بيانات السوق:
{market_data}

تحليل المبيعات:
{sales_data}

اقترح منتجات جديدة بصيغة JSON:
{{
    "trending_categories": [
        {{"category": "اسم الفئة", "demand": "high/medium", "reason": "السبب"}}
    ],
    "gap_analysis": [
        {{"gap": "وصف الفجوة", "opportunity": "الفرصة", "priority": "high/medium/low"}}
    ],
    "suggestions": [
        {{"name": "اسم المنتج المقترح", "category": "الفئة", "price_range": "100-200", "reason": "لماذا هذا المنتج", "potential": "high/medium"}}
    ],
    "market_trends": ["اتجاه 1", "اتجاه 2", "اتجاه 3"]
}}
"""

TRANSLATE_PROMPT = """Translate the following text from {source_lang} to {target_lang}.
Keep the tone, style, and meaning as close to the original as possible.
If the text contains Egyptian Arabic, translate naturally (not literally).

Text: {text}

Return ONLY the translated text, nothing else."""


# ============================================================
# Agent Functions
# ============================================================

async def generate_product_description(
    product_name: str,
    category: str = "",
    material: str = "",
    extra_details: str = "",
    market_context: str = "",
) -> dict:
    """توليد وصف منتج احترافي."""
    llm = get_llm(temperature=0.7)
    prompt = PRODUCT_DESCRIPTION_PROMPT.format(
        product_name=product_name,
        category=category or "غير محدد",
        material=material or "غير محدد",
        extra_details=extra_details or "لا يوجد",
        market_context=market_context or "لا تتوفر بيانات سوق",
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "description_ar": f"منتج مصري أصيل — {product_name}",
        "description_en": f"Authentic Egyptian product — {product_name}",
        "title_suggestions_ar": [product_name],
        "title_suggestions_en": [product_name],
        "category_suggestion": category or "أخرى",
        "category_confidence": 0.5,
        "seo_keywords": [],
        "marketing_highlights": [],
    })


async def suggest_price(
    product_name: str,
    category: str,
    material: str = "",
    market_data: str = "",
) -> dict:
    """اقتراح سعر تنافسي."""
    llm = get_fast_llm(temperature=0.3)
    prompt = PRICE_SUGGESTION_PROMPT.format(
        product_name=product_name,
        category=category,
        material=material or "غير محدد",
        market_data=market_data or "لا تتوفر بيانات",
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "suggested_price": 0,
        "price_range_min": 0,
        "price_range_max": 0,
        "market_average": 0,
        "reasoning": "لا تتوفر بيانات كافية",
        "confidence": 0.0,
    })


async def suggest_replies(
    customer_message: str,
    customer_name: str = "",
    context: str = "",
) -> dict:
    """اقتراح ردود ذكية على رسائل العملاء."""
    llm = get_llm(temperature=0.7)
    prompt = REPLY_SUGGESTIONS_PROMPT.format(
        customer_message=customer_message,
        customer_name=customer_name or "العميل",
        context=context or "محادثة عامة",
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "detected_intent": "general",
        "customer_sentiment": "neutral",
        "language_detected": "ar",
        "priority": "normal",
        "replies": [
            {"text": "شكراً لتواصلك! هنرد عليك في أقرب وقت 😊", "tone": "friendly", "confidence": 0.7},
        ],
    })


async def generate_content(
    content_type: str,
    product_name: str = "",
    bazaar_name: str = "",
    offer_details: str = "",
    target_audience: str = "tourists",
    language: str = "ar",
) -> dict:
    """توليد محتوى تسويقي."""
    llm = get_llm(temperature=0.8)
    prompt = CONTENT_GENERATION_PROMPT.format(
        content_type=content_type,
        product_name=product_name or "منتج",
        bazaar_name=bazaar_name or "بازار",
        offer_details=offer_details or "لا يوجد",
        target_audience=target_audience,
        language=language,
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "content": "",
        "hashtags": [],
        "call_to_action": "",
        "variations": [],
    })


async def generate_daily_digest(analytics_data: dict) -> dict:
    """توليد ملخص يومي ذكي."""
    llm = get_llm(temperature=0.6)
    prompt = DAILY_DIGEST_PROMPT.format(
        analytics_data=json.dumps(analytics_data, ensure_ascii=False, default=str),
        today=datetime.now().strftime("%Y-%m-%d %A"),
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "greeting": "صباح الخير! يوم جديد مليان فرص 🌅",
        "yesterday_summary": {},
        "today_goals": [],
        "alerts": [],
        "tip_of_day": "",
        "performance_score": 50,
    })


async def suggest_products(
    current_products: str,
    market_data: str = "",
    sales_data: str = "",
) -> dict:
    """اقتراح منتجات جديدة."""
    llm = get_llm(temperature=0.7)
    prompt = PRODUCT_SUGGESTIONS_PROMPT.format(
        current_products=current_products,
        market_data=market_data or "لا تتوفر بيانات",
        sales_data=sales_data or "لا تتوفر بيانات",
    )

    result = await llm.ainvoke(prompt)
    return _parse_json_response(result.content, {
        "trending_categories": [],
        "gap_analysis": [],
        "suggestions": [],
        "market_trends": [],
    })


async def translate_text(text: str, source_lang: str = "ar", target_lang: str = "en") -> str:
    """ترجمة نص."""
    llm = get_fast_llm(temperature=0.3)
    prompt = TRANSLATE_PROMPT.format(
        text=text,
        source_lang="Arabic" if source_lang == "ar" else "English",
        target_lang="English" if target_lang == "en" else "Arabic",
    )

    result = await llm.ainvoke(prompt)
    return result.content.strip()


async def generate_analytics_insights(analytics_data: dict) -> list[dict]:
    """توليد insights ذكية من بيانات التحليلات."""
    llm = get_fast_llm(temperature=0.5)
    prompt = f"""أنت محلل بيانات ذكي. حلل البيانات التالية واستخرج 3-5 insights مفيدة.

البيانات:
{json.dumps(analytics_data, ensure_ascii=False, default=str)}

أعط الإجابة بصيغة JSON array:
[
    {{"type": "success/warning/tip/danger", "icon": "📈/⚠️/💡/🔴", "title": "عنوان قصير", "text": "شرح مختصر ومفيد"}},
    ...
]

قواعد:
- استخدم الأرقام الحقيقية من البيانات
- كل insight يجب أن يكون actionable (يقدر صاحب البازار يعمل حاجة بيه)
- رتب حسب الأهمية
- اكتب بالعربية المصرية بشكل ودي
"""

    result = await llm.ainvoke(prompt)
    parsed = _parse_json_response(result.content, [])
    if isinstance(parsed, list):
        return parsed
    return []


# ============================================================
# Utility
# ============================================================

def _parse_json_response(text: str, fallback):
    """Wrapper for shared JSON parser with fallback support."""
    from utils.json_parser import parse_json_response
    parsed = parse_json_response(text)
    return parsed if parsed else fallback
