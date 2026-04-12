"""
📱 Owner AI API Routes — 8 endpoints لأصحاب البازارات
✅ Fixed: BUG-04 (import error), migrated to logging
"""
import json
import logging
from fastapi import APIRouter, HTTPException

from models.ai_models import (
    GenerateDescriptionRequest, GenerateDescriptionResponse,
    SuggestPriceRequest, SuggestPriceResponse,
    SuggestRepliesRequest, SuggestRepliesResponse,
    GenerateContentRequest, GenerateContentResponse,
    TranslateRequest, TranslateResponse,
    DailyDigestResponse, BazaarAnalyticsResponse,
    ProductSuggestionsResponse,
)
from agents.owner_assistant_agent import (
    generate_product_description, suggest_price,
    suggest_replies, generate_content,
    generate_daily_digest, suggest_products,
    translate_text, generate_analytics_insights,
)
from services.analytics_service import compute_bazaar_analytics, get_market_prices
# BUG-04 Fix: get_bazaar_products and get_bazaar_orders are in aws_db_service, NOT analytics_service
from services.aws_db_service import get_bazaar_products, get_bazaar_orders

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/owner/ai", tags=["Owner AI"])


# ============================================================
# 1. Generate Product Description
# ============================================================

@router.post("/generate-description", response_model=GenerateDescriptionResponse)
async def api_generate_description(request: GenerateDescriptionRequest):
    """✍️ توليد وصف منتج احترافي بالعربية والإنجليزية."""
    try:
        # Get market context if bazaar_id is provided
        market_context = ""
        if request.category:
            prices = await get_market_prices(request.category)
            market_context = f"متوسط السعر: {prices.get('average', 0)} ج.م | النطاق: {prices.get('min', 0)}-{prices.get('max', 0)} ج.م | عدد المنتجات المشابهة: {prices.get('count', 0)}"

        result = await generate_product_description(
            product_name=request.product_name,
            category=request.category or "",
            material=request.material or "",
            extra_details=request.extra_details or "",
            market_context=market_context,
        )

        return GenerateDescriptionResponse(**result)

    except Exception as e:
        logger.error(f"Generate description error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 2. Suggest Price
# ============================================================

@router.post("/suggest-price", response_model=SuggestPriceResponse)
async def api_suggest_price(request: SuggestPriceRequest):
    """💰 اقتراح سعر تنافسي بناءً على تحليل السوق."""
    try:
        market = await get_market_prices(request.category)
        market_data = json.dumps(market, ensure_ascii=False, default=str)

        result = await suggest_price(
            product_name=request.product_name,
            category=request.category,
            material=request.material or "",
            market_data=market_data,
        )

        # Enrich with actual market data
        result["similar_products"] = market.get("similar_products", [])
        if result.get("market_average", 0) == 0:
            result["market_average"] = market.get("average", 0)
        if result.get("price_range_min", 0) == 0:
            result["price_range_min"] = market.get("min", 0)
        if result.get("price_range_max", 0) == 0:
            result["price_range_max"] = market.get("max", 0)

        return SuggestPriceResponse(**result)

    except Exception as e:
        logger.error(f"Suggest price error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 3. Suggest Replies
# ============================================================

@router.post("/suggest-replies", response_model=SuggestRepliesResponse)
async def api_suggest_replies(request: SuggestRepliesRequest):
    """💬 اقتراح ردود ذكية على رسائل العملاء."""
    try:
        result = await suggest_replies(
            customer_message=request.customer_message,
            customer_name=request.customer_name or "",
            context=request.context or "",
        )

        return SuggestRepliesResponse(**result)

    except Exception as e:
        logger.error(f"Suggest replies error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 4. Daily Digest
# ============================================================

@router.get("/daily-digest/{bazaar_id}")
async def api_daily_digest(bazaar_id: str):
    """⚡ ملخص يومي ذكي لأداء البازار."""
    try:
        analytics = await compute_bazaar_analytics(bazaar_id, period="day")
        result = await generate_daily_digest(analytics)
        return result

    except Exception as e:
        logger.error(f"Daily digest error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 5. Analytics
# ============================================================

@router.get("/analytics/{bazaar_id}")
async def api_bazaar_analytics(bazaar_id: str, period: str = "week"):
    """📊 تحليلات ذكية مع بيانات charts وتنبؤات AI."""
    try:
        # Compute raw analytics
        analytics = await compute_bazaar_analytics(bazaar_id, period)

        # Generate AI insights
        insights = await generate_analytics_insights(analytics)

        # Combine
        analytics["ai_insights"] = insights

        # Simple prediction (linear extrapolation)
        revenue_data = analytics.get("charts_data", {}).get("revenue_line", [])
        if len(revenue_data) >= 3:
            recent = [d["revenue"] for d in revenue_data[-3:]]
            avg_daily = sum(recent) / len(recent) if recent else 0
            analytics["predictions"] = {
                "next_week_revenue": round(avg_daily * 7, 2),
                "confidence": 0.65 + (0.05 * min(len(revenue_data), 7)),
                "trend": analytics.get("revenue", {}).get("trend", "flat"),
            }
        else:
            analytics["predictions"] = {
                "next_week_revenue": 0,
                "confidence": 0.3,
                "trend": "insufficient_data",
            }

        # AI summary
        total_rev = analytics.get("revenue", {}).get("total", 0)
        change = analytics.get("revenue", {}).get("change_pct", 0)
        trend_emoji = "📈" if change > 0 else "📉" if change < 0 else "➡️"
        analytics["ai_summary"] = (
            f"{trend_emoji} إيرادات الفترة: {total_rev:,.0f} ج.م "
            f"({'↑' if change > 0 else '↓'} {abs(change):.1f}%) | "
            f"طلبات: {analytics.get('orders', {}).get('total', 0)} | "
            f"منتجات نشطة: {analytics.get('products', {}).get('active', 0)}"
        )

        return analytics

    except Exception as e:
        logger.error(f"Analytics error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 6. Generate Content
# ============================================================

@router.post("/generate-content", response_model=GenerateContentResponse)
async def api_generate_content(request: GenerateContentRequest):
    """📝 توليد محتوى تسويقي (إعلانات، سوشيال، عروض)."""
    try:
        result = await generate_content(
            content_type=request.content_type,
            product_name=request.product_name or "",
            bazaar_name=request.bazaar_name or "",
            offer_details=request.offer_details or "",
            target_audience=request.target_audience,
            language=request.language,
        )

        return GenerateContentResponse(**result)

    except Exception as e:
        logger.error(f"Content generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 7. Product Suggestions
# ============================================================

@router.get("/product-suggestions/{bazaar_id}")
async def api_product_suggestions(bazaar_id: str):
    """🔮 اقتراح منتجات جديدة بناءً على اتجاهات السوق."""
    try:
        products = await get_bazaar_products(bazaar_id)
        orders = await get_bazaar_orders(bazaar_id, days=30)

        current_products = json.dumps(
            [{"name": p.get("nameAr", ""), "category": p.get("category", ""), "price": p.get("price", 0)}
             for p in products[:20]],
            ensure_ascii=False,
        )

        # Simple sales data
        from collections import Counter
        sold_categories = Counter()
        for order in orders:
            items = order.get("items", [])
            if isinstance(items, list):
                for item in items:
                    sold_categories[item.get("category", "أخرى")] += 1

        sales_data = json.dumps(dict(sold_categories), ensure_ascii=False)

        result = await suggest_products(
            current_products=current_products,
            sales_data=sales_data,
        )

        return result

    except Exception as e:
        logger.error(f"Product suggestions error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 8. Translate
# ============================================================

@router.post("/translate", response_model=TranslateResponse)
async def api_translate(request: TranslateRequest):
    """🌐 ترجمة فورية عربي ↔ إنجليزي."""
    try:
        translated = await translate_text(
            text=request.text,
            source_lang=request.source_lang,
            target_lang=request.target_lang,
        )

        return TranslateResponse(
            translated_text=translated,
            source_lang=request.source_lang,
            target_lang=request.target_lang,
        )

    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
