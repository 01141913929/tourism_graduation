"""
🤖 AI Feature Models — Pydantic schemas for Owner & Admin AI APIs
"""
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


# ============================================================
# Shared Models
# ============================================================

class AIInsight(BaseModel):
    """A single AI-generated insight."""
    type: str = Field(..., description="success | warning | tip | danger")
    icon: str = "💡"
    title: str = ""
    text: str = ""


class ChartDataPoint(BaseModel):
    """A single data point for charts."""
    label: str
    value: float
    extra: dict = {}


# ============================================================
# Owner AI Models
# ============================================================

class GenerateDescriptionRequest(BaseModel):
    """Request to generate a product description."""
    product_name: str = Field(..., description="اسم المنتج")
    category: Optional[str] = None
    material: Optional[str] = None
    image_url: Optional[str] = None
    bazaar_id: Optional[str] = None
    extra_details: Optional[str] = None


class GenerateDescriptionResponse(BaseModel):
    """AI-generated product description."""
    description_ar: str
    description_en: str
    title_suggestions_ar: list[str] = []
    title_suggestions_en: list[str] = []
    category_suggestion: str = ""
    category_confidence: float = 0.0
    seo_keywords: list[str] = []
    marketing_highlights: list[str] = []


class SuggestPriceRequest(BaseModel):
    """Request to suggest a product price."""
    product_name: str
    category: str
    material: Optional[str] = None
    bazaar_id: Optional[str] = None


class SuggestPriceResponse(BaseModel):
    """AI-suggested pricing."""
    suggested_price: float
    price_range_min: float
    price_range_max: float
    market_average: float
    similar_products: list[dict] = []
    reasoning: str = ""
    confidence: float = 0.0


class SuggestRepliesRequest(BaseModel):
    """Request to suggest replies for customer messages."""
    customer_message: str
    customer_name: Optional[str] = None
    context: Optional[str] = None
    language: str = "ar"
    bazaar_id: Optional[str] = None


class SuggestRepliesResponse(BaseModel):
    """AI-suggested replies."""
    replies: list[dict] = []  # [{text, tone, confidence}]
    detected_intent: str = ""
    customer_sentiment: str = "neutral"
    language_detected: str = "ar"
    priority: str = "normal"


class GenerateContentRequest(BaseModel):
    """Request to generate marketing content."""
    content_type: str = Field(..., description="ad | social | seo | offer")
    product_name: Optional[str] = None
    offer_details: Optional[str] = None
    bazaar_name: Optional[str] = None
    target_audience: str = "tourists"
    language: str = "ar"


class GenerateContentResponse(BaseModel):
    """AI-generated marketing content."""
    content: str
    hashtags: list[str] = []
    call_to_action: str = ""
    variations: list[str] = []


class TranslateRequest(BaseModel):
    """Request to translate text."""
    text: str
    source_lang: str = "ar"
    target_lang: str = "en"


class TranslateResponse(BaseModel):
    """Translation result."""
    translated_text: str
    source_lang: str
    target_lang: str


class DailyDigestResponse(BaseModel):
    """AI daily digest for bazaar owner."""
    greeting: str
    yesterday_summary: dict = {}
    today_goals: list[str] = []
    alerts: list[AIInsight] = []
    tip_of_day: str = ""
    performance_score: float = 0.0


class BazaarAnalyticsResponse(BaseModel):
    """AI analytics response with chart data."""
    period: str
    # Revenue
    revenue: dict = {}
    # Top products
    top_products: list[dict] = []
    # Peak hours
    peak_hours: list[dict] = []
    # AI insights
    ai_insights: list[AIInsight] = []
    # Predictions
    predictions: dict = {}
    # Chart data
    charts_data: dict = {}
    # AI summary text
    ai_summary: str = ""


class ProductSuggestionsResponse(BaseModel):
    """AI product suggestions."""
    trending_categories: list[dict] = []
    gap_analysis: list[dict] = []
    suggestions: list[dict] = []
    market_trends: list[str] = []


# ============================================================
# Admin AI Models
# ============================================================

class AdminChatRequest(BaseModel):
    """Admin chatbot request."""
    message: str
    session_id: str = "admin_default"
    context: Optional[str] = None


class ModerationResult(BaseModel):
    """AI moderation result for a product."""
    product_id: str
    overall_score: int = Field(..., ge=0, le=100)
    status: str = Field(..., description="approved | needs_review | rejected")
    checks: dict = {}
    suggestions: list[str] = []
    auto_category: str = ""
    category_confidence: float = 0.0


class ApplicationAnalysis(BaseModel):
    """AI analysis of a bazaar application."""
    application_id: str
    overall_score: int = Field(..., ge=0, le=100)
    recommendation: str = ""
    checks: dict = {}
    risk_factors: list[str] = []
    suggestions: list[str] = []


class BusinessReportRequest(BaseModel):
    """Request for AI business report."""
    period: str = "month"
    focus: Optional[str] = None  # revenue, bazaars, products, customers


class BusinessReportResponse(BaseModel):
    """AI-generated business report."""
    period: str
    executive_summary: str
    key_metrics: dict = {}
    insights: list[AIInsight] = []
    trends: list[dict] = []
    recommendations: list[str] = []
    charts_data: dict = {}
    bazaar_rankings: list[dict] = []
    anomalies: list[dict] = []


class PlatformInsightsResponse(BaseModel):
    """Real-time platform insights."""
    health_score: int = 0
    active_bazaars: int = 0
    total_bazaars: int = 0
    insights: list[AIInsight] = []
    alerts: list[AIInsight] = []
    bazaar_tiers: dict = {}
    quick_stats: dict = {}


class GenerateMessageRequest(BaseModel):
    """Request to generate admin message."""
    message_type: str = Field(..., description="approval | rejection | warning | reminder | report")
    bazaar_name: str
    context: Optional[str] = None
    custom_notes: Optional[str] = None


class GenerateMessageResponse(BaseModel):
    """AI-generated admin message."""
    subject: str
    body: str
    tone: str = "professional"
    variations: list[dict] = []


class PromotionSuggestion(BaseModel):
    """A single promotion suggestion."""
    type: str  # discount, coupon, bundle, seasonal
    title: str
    description: str
    target_products: list[str] = []
    target_bazaars: list[str] = []
    estimated_impact: str = ""
    priority: str = "medium"


class PromotionSuggestionsResponse(BaseModel):
    """AI promotion suggestions."""
    suggestions: list[PromotionSuggestion] = []
    seasonal_events: list[dict] = []
    market_analysis: str = ""
