"""
🛡️ Moderation Agent — مراقبة وفحص المنتجات والبازارات بالذكاء الاصطناعي
✅ Fixed: BUG-02 (doc.to_dict()), migrated to logging
"""
import logging
from services.gemini_service import get_llm
from services.aws_db_service import get_product_by_id, get_bazaar_by_id, get_bazaar_application
from services.analytics_service import get_market_prices

logger = logging.getLogger(__name__)

# ============================================================
# System Prompts
# ============================================================

MODERATE_PRODUCT_PROMPT = """أنت مراقب جودة محتوى في منصة سياحة مصرية.

مهمتك: فحص منتج جديد والتأكد من جودته قبل العرض.

بيانات المنتج:
- الاسم (عربي): {name_ar}
- الاسم (إنجليزي): {name_en}
- الوصف (عربي): {desc_ar}
- الوصف (إنجليزي): {desc_en}
- السعر: {price} ج.م
- الفئة: {category}
- رابط الصورة: {image_url}

بيانات السوق:
- متوسط السعر لنفس الفئة: {avg_price} ج.م
- نطاق الأسعار: {price_range}

قيّم المنتج بصيغة JSON:
{{
    "overall_score": نقاط_من_100,
    "status": "approved / needs_review / rejected",
    "checks": {{
        "name_quality": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "ملاحظة"
        }},
        "description_quality": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "ملاحظة"
        }},
        "price_analysis": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "مقارنة السعر بالسوق"
        }},
        "image_presence": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "ملاحظة عن الصورة"
        }},
        "category_match": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل الفئة صحيحة"
        }},
        "content_safety": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل المحتوى مناسب"
        }}
    }},
    "auto_category": "الفئة المقترحة",
    "category_confidence": 0.9,
    "suggestions": [
        "اقتراح تحسين 1",
        "اقتراح تحسين 2"
    ]
}}

معايير التقييم:
- 80+ = approved (موافقة تلقائية)
- 50-79 = needs_review (يحتاج مراجعة يدوية)
- أقل من 50 = rejected (مرفوض — محتوى ضعيف أو مخالف)

ما يُرفض:
- منتجات بدون وصف
- أسعار غير منطقية (أعلى 300% من المتوسط أو 0)
- محتوى مخالف أو مسيء
- صور غير موجودة
"""

ANALYZE_APPLICATION_PROMPT = """أنت مراجع طلبات بازارات جديدة في منصة سياحة مصرية.

بيانات الطلب:
- اسم البازار: {bazaar_name}
- وصف البازار: {description}
- الموقع: {location}
- رقم الهاتف: {phone}
- البريد الإلكتروني: {email}
- اسم المالك: {owner_name}

قيّم الطلب بصيغة JSON:
{{
    "overall_score": نقاط_من_100,
    "recommendation": "approve / review / reject — مع سبب مختصر",
    "checks": {{
        "name_validation": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل الاسم واضح ومناسب؟"
        }},
        "description_quality": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل الوصف مفصل وواضح؟"
        }},
        "location_validation": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل الموقع مكتمل ومنطقي؟"
        }},
        "contact_info": {{
            "score": 0-100,
            "pass": true/false,
            "feedback": "هل معلومات التواصل صحيحة؟"
        }}
    }},
    "risk_factors": ["عامل خطر 1 إن وُجد"],
    "suggestions": ["اقتراح لتحسين الطلب"]
}}
"""


# ============================================================
# Agent Functions
# ============================================================

async def moderate_product(product_id: str) -> dict:
    """فحص منتج بالذكاء الاصطناعي."""
    product = await get_product_by_id(product_id)
    if not product:
        return {
            "product_id": product_id,
            "overall_score": 0,
            "status": "rejected",
            "checks": {},
            "suggestions": ["المنتج غير موجود"],
            "auto_category": "",
            "category_confidence": 0.0,
        }

    # Get market prices for comparison
    category = product.get("category", "أخرى")
    market = await get_market_prices(category)

    llm = get_llm(temperature=0.3)
    prompt = MODERATE_PRODUCT_PROMPT.format(
        name_ar=product.get("nameAr", ""),
        name_en=product.get("nameEn", ""),
        desc_ar=product.get("descriptionAr", ""),
        desc_en=product.get("descriptionEn", ""),
        price=product.get("price", 0),
        category=category,
        image_url=product.get("imageUrl", "لا يوجد"),
        avg_price=market.get("average", 0),
        price_range=f"{market.get('min', 0)} - {market.get('max', 0)}",
    )

    result = await llm.ainvoke(prompt)
    parsed = _parse_json_response(result.content, {
        "overall_score": 50,
        "status": "needs_review",
        "checks": {},
        "suggestions": [],
        "auto_category": category,
        "category_confidence": 0.5,
    })

    parsed["product_id"] = product_id
    return parsed


async def analyze_application(application_id: str) -> dict:
    """تحليل طلب بازار جديد."""
    # BUG-02 Fix: Use get_bazaar_application and work with the dict directly
    # (removed the old Firestore `doc.to_dict()` call)
    data = await get_bazaar_application(application_id)

    if not data:
        # Fallback: try bazaar details
        data = await get_bazaar_by_id(application_id)

    if not data:
        return {
            "application_id": application_id,
            "overall_score": 0,
            "recommendation": "الطلب غير موجود",
            "checks": {},
            "risk_factors": [],
            "suggestions": [],
        }

    # data is already a dict from AWS — no need for doc.to_dict()
    llm = get_llm(temperature=0.3)
    prompt = ANALYZE_APPLICATION_PROMPT.format(
        bazaar_name=data.get("nameAr", data.get("name_ar", "")),
        description=data.get("descriptionAr", data.get("description_ar", "")),
        location=data.get("address", data.get("location", "")),
        phone=data.get("phone", ""),
        email=data.get("email", ""),
        owner_name=data.get("ownerName", data.get("owner_name", "")),
    )

    result = await llm.ainvoke(prompt)
    parsed = _parse_json_response(result.content, {
        "overall_score": 50,
        "recommendation": "needs_review",
        "checks": {},
        "risk_factors": [],
        "suggestions": [],
    })

    parsed["application_id"] = application_id
    return parsed


async def batch_moderate_products(product_ids: list[str], max_concurrent: int = 5) -> list[dict]:
    """فحص مجموعة منتجات بحد أقصى للتزامن."""
    import asyncio
    sem = asyncio.Semaphore(max_concurrent)

    async def _sem_moderate(pid):
        async with sem:
            return await moderate_product(pid)

    tasks = [_sem_moderate(pid) for pid in product_ids]
    return await asyncio.gather(*tasks, return_exceptions=True)


# ============================================================
# Utility
# ============================================================

def _parse_json_response(text: str, fallback):
    """Wrapper for shared JSON parser with fallback support."""
    from utils.json_parser import parse_json_response
    parsed = parse_json_response(text)
    return parsed if parsed else fallback
