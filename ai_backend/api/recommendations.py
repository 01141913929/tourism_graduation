"""
🎯 AI Recommendations API — نظام اقتراحات ذكي ثلاثي الطبقات
  طبقة 1: LLM-Powered — اقتراحات شخصية بالذكاء الاصطناعي
  طبقة 2: Content-Based Scoring — تطابق المحتوى بخوارزمية نقاط
  طبقة 3: Popularity-Based — الأعلى تقييماً في فئات المستخدم
"""
import asyncio
import json
import logging
from fastapi import APIRouter, Query
from fastapi.responses import StreamingResponse
from services.aws_db_service import (
    get_user_memory, get_all_products,
)
from services.gemini_service import get_fast_llm

router = APIRouter(prefix="/api", tags=["Recommendations"])

logger = logging.getLogger(__name__)


# ============================================================
# 📊 خوارزمية حساب النقاط (Content-Based Scoring)
# ============================================================

def _score_product(product: dict, user_prefs: dict, favorites: list[str]) -> float:
    """حساب نقاط التطابق بين منتج وتفضيلات المستخدم."""
    score = 0.0
    pid = product.get("id", "")

    # لو المنتج في المفضلات → تجاهله (مشفهوش الأول)
    if pid in favorites:
        return -1.0

    # لو مش متاح
    if not product.get("isActive", True) or not product.get("isInStock", True):
        return -1.0

    fav_categories = user_prefs.get("favorite_categories", [])
    fav_bazaars = user_prefs.get("favorite_bazaars", [])
    price_range = user_prefs.get("price_range", "")
    interests = user_prefs.get("interests", [])

    # === تطابق الفئة (+30) ===
    category = product.get("category", "")
    if category and category in fav_categories:
        score += 30

    # === تطابق البازار (+15) ===
    bazaar_id = product.get("bazaarId", "")
    if bazaar_id and bazaar_id in fav_bazaars:
        score += 15

    # === نطاق السعر (+20) ===
    price = product.get("price", 0)
    if price_range:
        if price_range == "رخيص" and price < 200:
            score += 20
        elif price_range == "متوسط" and 200 <= price <= 800:
            score += 20
        elif price_range == "غالي" and price > 800:
            score += 20

    # === التقييم العالي (+15) ===
    rating = product.get("rating", 0)
    if rating >= 4.5:
        score += 15
    elif rating >= 4.0:
        score += 10
    elif rating >= 3.5:
        score += 5

    # === عليه خصم (+10) ===
    if product.get("oldPrice") and product.get("oldPrice", 0) > price:
        score += 10

    # === منتج جديد (+10) ===
    if product.get("isNew", False):
        score += 10

    # === منتج مميز (+5) ===
    if product.get("isFeatured", False):
        score += 5

    # === تطابق الاهتمامات (+20) ===
    if interests:
        name = (product.get("nameAr", "") + " " + product.get("descriptionAr", "")).lower()
        for interest in interests:
            if interest.lower() in name:
                score += 20
                break

    return score


# ============================================================
# 🧠 اقتراحات LLM (الطبقة 1 — الأذكى)
# ============================================================

async def _llm_recommendations(
    products: list[dict],
    user_prefs: dict,
    favorites: list[str],
    limit: int = 6,
) -> list[dict]:
    """اقتراحات بالذكاء الاصطناعي — LLM يختار أنسب المنتجات."""
    if not user_prefs or not products:
        return []

    # تجهيز ملخص المنتجات المتاحة (أعلى 30 بالـ scoring أولاً)
    scored = []
    for p in products:
        s = _score_product(p, user_prefs, favorites)
        if s >= 0:
            scored.append((p, s))

    scored.sort(key=lambda x: x[1], reverse=True)
    top_candidates = scored[:30]  # أفضل 30 مرشح

    if not top_candidates:
        return []

    # بناء ملخص للـ LLM
    products_summary = "\n".join([
        f"ID:{p['id']} | {p.get('nameAr','')} | {p.get('category','')} | "
        f"{p.get('price',0)} ج | ⭐{p.get('rating',0)} | "
        f"{'خصم' if p.get('oldPrice') else ''}"
        for p, _ in top_candidates
    ])

    prefs_text = json.dumps(user_prefs, ensure_ascii=False, indent=0)

    prompt = f"""أنت نظام اقتراحات ذكي لتطبيق سياحة مصرية.

تفضيلات المستخدم:
{prefs_text}

المنتجات المتاحة:
{products_summary}

اختر أفضل {limit} منتجات تناسب هذا المستخدم. رتبهم من الأنسب للأقل.
لكل منتج اكتب سبب اختياره في جملة قصيرة.

أجب بصيغة JSON فقط:
{{"picks": [{{"id": "...", "reason": "..."}}]}}"""

    try:
        llm = get_fast_llm(temperature=0.3)
        result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=20.0)
        content = result.content.strip()

        # استخراج JSON
        if "```" in content:
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]

        data = json.loads(content)
        picks = data.get("picks", [])

        # ربط الـ IDs بالمنتجات الكاملة
        product_map = {p["id"]: p for p in products}
        result_products = []

        for pick in picks[:limit]:
            pid = pick.get("id", "")
            if pid in product_map:
                prod = dict(product_map[pid])
                prod["ai_reason"] = pick.get("reason", "")
                prod["recommendation_type"] = "ai_pick"
                result_products.append(prod)

        return result_products

    except Exception as e:
        logger.warning(f"LLM recommendations failed: {e}")
        return []


# ============================================================
# 📊 اقتراحات Content-Based (الطبقة 2)
# ============================================================

def _content_based_recommendations(
    products: list[dict],
    user_prefs: dict,
    favorites: list[str],
    exclude_ids: set[str],
    limit: int = 6,
) -> list[dict]:
    """اقتراحات بتطابق المحتوى — خوارزمية scoring."""
    scored = []
    for p in products:
        if p.get("id", "") in exclude_ids:
            continue
        s = _score_product(p, user_prefs, favorites)
        if s > 0:
            scored.append((p, s))

    scored.sort(key=lambda x: x[1], reverse=True)

    result = []
    for p, score in scored[:limit]:
        prod = dict(p)
        prod["match_score"] = round(score, 1)
        prod["recommendation_type"] = "content_match"
        result.append(prod)

    return result


# ============================================================
# ⭐ اقتراحات Popularity (الطبقة 3)
# ============================================================

def _popularity_recommendations(
    products: list[dict],
    user_prefs: dict,
    favorites: list[str],
    exclude_ids: set[str],
    limit: int = 6,
) -> list[dict]:
    """أعلى تقييماً في فئات المستخدم المفضلة."""
    fav_categories = user_prefs.get("favorite_categories", [])

    candidates = [
        p for p in products
        if p.get("id", "") not in exclude_ids
        and p.get("id", "") not in favorites
        and p.get("isActive", True)
        and (not fav_categories or p.get("category", "") in fav_categories)
    ]

    # ترتيب بالتقييم ثم عدد المراجعات
    candidates.sort(
        key=lambda p: (p.get("rating", 0), p.get("reviewCount", 0)),
        reverse=True,
    )

    result = []
    for p in candidates[:limit]:
        prod = dict(p)
        prod["recommendation_type"] = "trending"
        result.append(prod)

    return result


# ============================================================
# 🌐 API Endpoint
# ============================================================

@router.get("/recommendations/{user_id}")
async def get_recommendations(
    user_id: str,
    limit: int = Query(default=6, ge=1, le=20),
):
    """🎯 اقتراحات ذكية ثلاثية الطبقات لمستخدم محدد."""

    # === تحميل البيانات بالتوازي ===
    user_memory_task = get_user_memory(user_id)
    products_task = get_all_products()

    user_memory, all_products = await asyncio.gather(
        user_memory_task, products_task,
    )

    user_prefs = user_memory.get("preferences", {})
    favorites = user_memory.get("favorites", [])

    # لو مفيش تفضيلات → اقتراحات عامة (أفضل تقييم)
    if not user_prefs:
        user_prefs = {"favorite_categories": [], "interests": []}

    # ============ الطبقة 1: LLM Recommendations ============
    ai_picks = await _llm_recommendations(all_products, user_prefs, favorites, limit)
    ai_ids = {p["id"] for p in ai_picks}

    # ============ الطبقة 2: Content-Based ============
    content_recs = _content_based_recommendations(
        all_products, user_prefs, favorites, ai_ids, limit,
    )
    content_ids = {p["id"] for p in content_recs}

    # ============ الطبقة 3: Popularity ============
    all_exclude = ai_ids | content_ids
    popular_recs = _popularity_recommendations(
        all_products, user_prefs, favorites, all_exclude, limit,
    )

    return {
        "user_id": user_id,
        "sections": [
            {
                "id": "ai_picks",
                "title_ar": "مقترحة لك 💎",
                "title_en": "Picked for You 💎",
                "subtitle_ar": "اقتراحات ذكية بناءً على ذوقك",
                "subtitle_en": "Smart picks based on your taste",
                "type": "ai",
                "products": ai_picks,
            },
            {
                "id": "content_match",
                "title_ar": "تناسب اهتماماتك ✨",
                "title_en": "Matches Your Interests ✨",
                "subtitle_ar": "منتجات مشابهة لما تحبه",
                "subtitle_en": "Similar to what you love",
                "type": "content",
                "products": content_recs,
            },
            {
                "id": "trending",
                "title_ar": "رائج في فئتك ⭐",
                "title_en": "Trending in Your Category ⭐",
                "subtitle_ar": "الأعلى تقييماً فيما تفضله",
                "subtitle_en": "Top rated in your favorites",
                "type": "popularity",
                "products": popular_recs,
            },
        ],
        "total_recommendations": len(ai_picks) + len(content_recs) + len(popular_recs),
    }


@router.get("/recommendations/{user_id}/quick")
async def get_quick_recommendations(
    user_id: str,
    limit: int = Query(default=6, ge=1, le=20),
):
    """⚡ اقتراحات سريعة (بدون LLM) — Content-Based + Popularity فقط."""
    user_memory = await get_user_memory(user_id)
    all_products = await get_all_products()

    user_prefs = user_memory.get("preferences", {})
    favorites = user_memory.get("favorites", [])

    if not user_prefs:
        user_prefs = {"favorite_categories": [], "interests": []}

    content_recs = _content_based_recommendations(
        all_products, user_prefs, favorites, set(), limit,
    )
    content_ids = {p["id"] for p in content_recs}

    popular_recs = _popularity_recommendations(
        all_products, user_prefs, favorites, content_ids, limit,
    )

    return {
        "user_id": user_id,
        "products": content_recs + popular_recs,
        "total": len(content_recs) + len(popular_recs),
    }


@router.get("/recommendations/{user_id}/stream")
async def stream_recommendations(
    user_id: str,
    limit: int = Query(default=6, ge=1, le=20),
):
    """🌊 اقتراحات Stream (SSE) — ترسل Content/Popularity فوراً، ثم LLM picks."""

    async def generate_recommendations():
        try:
            user_memory_task = get_user_memory(user_id)
            products_task = get_all_products()

            user_memory, all_products = await asyncio.gather(
                user_memory_task, products_task,
            )

            user_prefs = user_memory.get("preferences", {})
            favorites = user_memory.get("favorites", [])

            if not user_prefs:
                user_prefs = {"favorite_categories": [], "interests": []}

            # ============ 1. إرسال Content & Popularity فوراً ============
            content_recs = _content_based_recommendations(
                all_products, user_prefs, favorites, set(), limit,
            )
            content_ids = {p["id"] for p in content_recs}

            popular_recs = _popularity_recommendations(
                all_products, user_prefs, favorites, content_ids, limit,
            )

            initial_data = {
                "type": "quick_results",
                "sections": [
                    {
                        "id": "content_match",
                        "title_ar": "تناسب اهتماماتك ✨",
                        "title_en": "Matches Your Interests ✨",
                        "subtitle_ar": "منتجات مشابهة لما تحبه",
                        "subtitle_en": "Similar to what you love",
                        "type": "content",
                        "products": content_recs,
                    },
                    {
                        "id": "trending",
                        "title_ar": "رائج في فئتك ⭐",
                        "title_en": "Trending in Your Category ⭐",
                        "subtitle_ar": "الأعلى تقييماً فيما تفضله",
                        "subtitle_en": "Top rated in your favorites",
                        "type": "popularity",
                        "products": popular_recs,
                    },
                ]
            }
            
            yield f"data: {json.dumps(initial_data, ensure_ascii=False)}\n\n"

            # ============ 2. حساب الـ LLM Picks (يأخذ وقت) ============
            ai_picks = await _llm_recommendations(all_products, user_prefs, favorites, limit)
            
            if ai_picks:
                final_data = {
                    "type": "llm_results",
                    "section": {
                        "id": "ai_picks",
                        "title_ar": "مقترحة لك 💎",
                        "title_en": "Picked for You 💎",
                        "subtitle_ar": "اقتراحات ذكية بناءً على ذوقك",
                        "subtitle_en": "Smart picks based on your taste",
                        "type": "ai",
                        "products": ai_picks,
                    }
                }
                yield f"data: {json.dumps(final_data, ensure_ascii=False)}\n\n"

            yield "data: [DONE]\n\n"

        except Exception as e:
            logger.warning(f"Streaming Error: {e}")
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
            yield "data: [DONE]\n\n"

    return StreamingResponse(generate_recommendations(), media_type="text/event-stream")

