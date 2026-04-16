"""
🛡️ Moderation Agent
Used exclusively by the admin application to review and approve/reject products and bazaars.
"""
import logging
from core.llm_service import get_llm
from core.db_service import get_product_by_id, get_bazaar_application, get_bazaar_by_id, get_market_prices
from core.json_utils import parse_json_response

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

بيانات السوق لنفس الفئة:
- متوسط السعر: {avg_price} ج.م
- نطاق الأسعار: {price_range}

قيّم المنتج بصيغة JSON:
{{
    "overall_score": نقاط_من_100,
    "status": "approved | needs_review | rejected",
    "checks": {{
        "name_quality": {{"score": 0, "pass": true, "feedback": ".."}},
        "description_quality": {{"score": 0, "pass": true, "feedback": ".."}},
        "price_analysis": {{"score": 0, "pass": true, "feedback": ".."}},
        "image_presence": {{"score": 0, "pass": true, "feedback": ".."}},
        "category_match": {{"score": 0, "pass": true, "feedback": ".."}},
        "content_safety": {{"score": 0, "pass": true, "feedback": ".."}}
    }},
    "auto_category": "الفئة المقترحة",
    "category_confidence": 0.9,
    "suggestions": ["اقتراح 1"]
}}

معايير: 80+ (موافقة تلقائية), 50-79 (مراجعة), <50 (مرفوض)
"""

ANALYZE_APPLICATION_PROMPT = """أنت مراجع طلبات انضمام بازارات في منصة سياحة مصرية.

بيانات الطلب:
- البازار: {bazaar_name}
- الوصف: {description}
- العنوان: {location}
- رقم الهاتف: {phone}
- البريد: {email}
- المالك: {owner_name}

قيّم الطلب بصيغة JSON:
{{
    "overall_score": 0,
    "recommendation": "approve | review | reject",
    "checks": {{
        "name_validation": {{"score": 0, "pass": true, "feedback": ".."}},
        "description_quality": {{"score": 0, "pass": true, "feedback": ".."}},
        "location_validation": {{"score": 0, "pass": true, "feedback": ".."}},
        "contact_info": {{"score": 0, "pass": true, "feedback": ".."}}
    }},
    "risk_factors": [],
    "suggestions": []
}}
"""

# ============================================================
# Agent Execution
# ============================================================

async def moderate_product(product_id: str) -> dict:
    """Analyze a single product and return a moderation score and decision."""
    product = await get_product_by_id(product_id)
    if not product:
        return {
            "product_id": product_id,
            "overall_score": 0, "status": "rejected", "checks": {},
            "suggestions": ["المنتج غير موجود ببيانات النظام."],
            "auto_category": "", "category_confidence": 0.0,
        }

    category = product.get("category", "أخرى")
    market = await get_market_prices(category)

    llm = get_llm(temperature=0.3, app_id="admin")
    prompt = MODERATE_PRODUCT_PROMPT.format(
        name_ar=product.get("nameAr", ""), name_en=product.get("nameEn", ""),
        desc_ar=product.get("descriptionAr", ""), desc_en=product.get("descriptionEn", ""),
        price=product.get("price", 0), category=category,
        image_url=product.get("imageUrl", "لا يوجد"),
        avg_price=market.get("average", 0),
        price_range=f"{market.get('min', 0)} - {market.get('max', 0)}",
    )

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    if not parsed:
        parsed = {"overall_score": 50, "status": "needs_review", "checks": {}, "suggestions": []}

    parsed["product_id"] = product_id
    return parsed


async def analyze_application(application_id: str) -> dict:
    """Analyze a newly submitted bazaar application."""
    data = await get_bazaar_application(application_id)
    if not data:
        data = await get_bazaar_by_id(application_id) # fallback

    if not data:
        return {
            "application_id": application_id, "overall_score": 0,
            "recommendation": "reject", "checks": {},
            "risk_factors": ["الطلب المعرف غير موجود بالقاعدة"], "suggestions": []
        }

    llm = get_llm(temperature=0.3, app_id="admin")
    prompt = ANALYZE_APPLICATION_PROMPT.format(
        bazaar_name=data.get("nameAr", data.get("name_ar", "")),
        description=data.get("descriptionAr", data.get("description_ar", "")),
        location=data.get("address", data.get("location", "")),
        phone=data.get("phone", ""),
        email=data.get("email", ""),
        owner_name=data.get("ownerName", data.get("owner_name", "")),
    )

    result = await llm.ainvoke(prompt)
    parsed = parse_json_response(result.content)
    if not parsed:
         parsed = {"overall_score": 50, "recommendation": "review", "checks": {}, "suggestions": []}

    parsed["application_id"] = application_id
    return parsed
