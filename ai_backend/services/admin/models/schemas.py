"""
🔴 Admin AI — Pydantic Schemas (Request/Response)
Strict validation for all admin endpoints.
These models match the Flutter Admin Panel frontend contract.
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


# ============================================================
# 1. Admin Chat
# ============================================================

class AdminChatRequest(BaseModel):
    """POST /api/admin/ai/chat — Admin chatbot request."""
    message: str = Field(..., min_length=1, max_length=2000, description="سؤال الأدمن")
    session_id: str = Field(default="admin_default", description="معرف الجلسة")
    context: Optional[str] = Field(default=None, max_length=5000, description="سياق إضافي اختياري")


class AdminChatResponse(BaseModel):
    """Response from admin chat endpoint."""
    text: str = Field(..., description="رد الـ AI بتنسيق Markdown")
    quick_actions: list[str] = Field(default_factory=list, description="أسئلة متابعة مقترحة")
    charts_data: Optional[dict] = Field(default=None, description="بيانات الرسوم البيانية")
    data_tables: Optional[dict] = Field(default=None, description="جداول بيانات")


# ============================================================
# 2. Moderation
# ============================================================

class ModerationCheckResult(BaseModel):
    """Single moderation check result."""
    score: int = Field(..., ge=0, le=100)
    passed: bool = Field(..., alias="pass")
    feedback: str = ""

    class Config:
        populate_by_name = True


class ModerationResponse(BaseModel):
    """GET /api/admin/ai/moderate-product/{id} — Product moderation result."""
    product_id: str
    overall_score: int = Field(..., ge=0, le=100)
    status: str = Field(..., description="approved | needs_review | rejected")
    checks: dict = Field(default_factory=dict, description="Individual check results")
    suggestions: list[str] = Field(default_factory=list)
    auto_category: str = ""
    category_confidence: float = Field(default=0.0, ge=0.0, le=1.0)


# ============================================================
# 3. Application Analysis
# ============================================================

class ApplicationAnalysisResponse(BaseModel):
    """GET /api/admin/ai/analyze-application/{id} — Bazaar application analysis."""
    application_id: str
    overall_score: int = Field(..., ge=0, le=100)
    recommendation: str = Field(..., description="approve | review | reject — with reason")
    checks: dict = Field(default_factory=dict)
    risk_factors: list[str] = Field(default_factory=list)
    suggestions: list[str] = Field(default_factory=list)


# ============================================================
# 4. Business Report
# ============================================================

class ReportPeriod(str, Enum):
    """Valid report periods."""
    WEEK = "week"
    MONTH = "month"
    QUARTER = "quarter"
    YEAR = "year"


class ReportFocus(str, Enum):
    """Valid report focus areas."""
    REVENUE = "revenue"
    BAZAARS = "bazaars"
    PRODUCTS = "products"
    CUSTOMERS = "customers"


class BusinessReportRequest(BaseModel):
    """POST /api/admin/ai/business-report — Request a BI report."""
    period: ReportPeriod = Field(default=ReportPeriod.MONTH)
    focus: Optional[ReportFocus] = Field(default=None, description="Optional focus area")


class BusinessReportResponse(BaseModel):
    """AI-generated business report."""
    period: str
    executive_summary: str = ""
    key_metrics: dict = Field(default_factory=dict)
    insights: list[AIInsight] = Field(default_factory=list)
    trends: list[dict] = Field(default_factory=list)
    recommendations: list[str] = Field(default_factory=list)
    charts_data: dict = Field(default_factory=dict)
    bazaar_rankings: list[dict] = Field(default_factory=list)
    anomalies: list[dict] = Field(default_factory=list)


# ============================================================
# 5. Platform Insights
# ============================================================

class PlatformInsightsResponse(BaseModel):
    """GET /api/admin/ai/platform-insights — Real-time platform insights."""
    health_score: int = Field(default=0, ge=0, le=100)
    insights: list[AIInsight] = Field(default_factory=list)
    alerts: list[AIInsight] = Field(default_factory=list)
    bazaar_tiers: dict = Field(default_factory=dict)
    quick_stats: dict = Field(default_factory=dict)


# ============================================================
# 6. Generate Message
# ============================================================

class MessageType(str, Enum):
    """Valid admin message types."""
    APPROVAL = "approval"
    REJECTION = "rejection"
    WARNING = "warning"
    REMINDER = "reminder"
    REPORT = "report"


class GenerateMessageRequest(BaseModel):
    """POST /api/admin/ai/generate-message — Generate an admin message."""
    message_type: MessageType = Field(..., description="Type of message to generate")
    bazaar_name: str = Field(..., min_length=1, max_length=200)
    context: Optional[str] = Field(default=None, max_length=2000)
    custom_notes: Optional[str] = Field(default=None, max_length=2000)


class GenerateMessageResponse(BaseModel):
    """AI-generated admin message."""
    subject: str
    body: str
    tone: str = "professional"
    variations: list[dict] = Field(default_factory=list)


# ============================================================
# 7. Promotion Suggestions
# ============================================================

class PromotionSuggestion(BaseModel):
    """A single promotion suggestion."""
    type: str = Field(..., description="discount | coupon | bundle | seasonal")
    title: str
    description: str
    target_products: list[str] = Field(default_factory=list)
    target_bazaars: list[str] = Field(default_factory=list)
    estimated_impact: str = ""
    priority: str = "medium"


class PromotionSuggestionsResponse(BaseModel):
    """GET /api/admin/ai/promotion-suggestions — AI promotion suggestions."""
    suggestions: list[PromotionSuggestion] = Field(default_factory=list)
    seasonal_events: list[dict] = Field(default_factory=list)
    market_analysis: str = ""
