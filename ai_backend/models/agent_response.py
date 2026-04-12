"""
🤖 Agent Response Models — موديلات ردود الوكلاء
"""
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class SentimentType(str, Enum):
    """أنواع المشاعر المدعومة."""
    POSITIVE = "positive"        # 😊 متحمس / سعيد
    NEUTRAL = "neutral"          # 😐 محايد
    NEGATIVE = "negative"        # 😤 محبط / زعلان
    CURIOUS = "curious"          # 🤔 فضولي / مهتم
    CONFUSED = "confused"        # 😵 محتار
    EXCITED = "excited"          # 🤩 متحمس جداً


class SentimentResult(BaseModel):
    """نتيجة تحليل المشاعر."""
    sentiment: SentimentType = SentimentType.NEUTRAL
    confidence: float = Field(default=0.5, ge=0.0, le=1.0)
    detected_emotion: str = ""
    adaptation_note: str = Field(
        default="",
        description="ملاحظة عن كيف يتكيف الرد مع المزاج"
    )


class ProactiveSuggestion(BaseModel):
    """اقتراح تلقائي بدون ما المستخدم يسأل."""
    type: str = Field(description="نوع الاقتراح: product/history/bazaar/tip")
    title: str = Field(description="عنوان الاقتراح")
    message: str = Field(description="نص الاقتراح")
    related_id: Optional[str] = Field(None, description="ID المنتج/الأثر/البازار المرتبط")
    emoji: str = "💡"


class AgentResponse(BaseModel):
    """رد وكيل منظم — بيتحول لـ ChatResponse في النهاية."""
    agent_name: str
    text: str
    sentiment: SentimentResult = Field(default_factory=SentimentResult)
    suggestions: list[ProactiveSuggestion] = Field(default_factory=list)
    cards_data: list[dict] = Field(default_factory=list)
    sources: list[str] = Field(default_factory=list)
    topics_detected: list[str] = Field(default_factory=list)
    confidence: float = Field(default=0.8, description="مدى ثقة الوكيل في ردّه")
