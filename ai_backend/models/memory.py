"""
💾 Memory Models — موديلات نظام الذاكرة
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class UserPreferences(BaseModel):
    """تفضيلات المستخدم المتعلمة من المحادثات."""
    favorite_categories: list[str] = Field(default_factory=list, description="الفئات المفضلة")
    price_range: str = Field(default="غير محدد", description="نطاق السعر المفضل")
    preferred_language: str = Field(default="ar", description="اللغة المفضلة")
    interests: list[str] = Field(default_factory=list, description="الاهتمامات (تاريخ، تسوق، سياحة)")
    sentiment_history: list[str] = Field(default_factory=list, description="سجل المشاعر")
    favorite_eras: list[str] = Field(default_factory=list, description="العصور التاريخية المفضلة")
    visited_bazaars: list[str] = Field(default_factory=list, description="البازارات اللي زارها")
    purchased_categories: list[str] = Field(default_factory=list, description="فئات المنتجات اللي اشتراها")


class ConversationEpisode(BaseModel):
    """حلقة محادثة — ملخص لجلسة سابقة."""
    session_id: str
    summary: str = Field(description="ملخص المحادثة")
    topics: list[str] = Field(default_factory=list, description="المواضيع اللي اتناقشت")
    products_discussed: list[str] = Field(default_factory=list, description="المنتجات اللي اتكلم عنها")
    sentiment: str = Field(default="neutral", description="المزاج العام للمحادثة")
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    message_count: int = Field(default=0, description="عدد الرسائل")


class SessionContext(BaseModel):
    """سياق الجلسة الحالية — الذاكرة العاملة."""
    session_id: str
    user_id: str = ""
    messages_count: int = 0
    current_topic: str = ""
    topics_discussed: list[str] = Field(default_factory=list)
    products_mentioned: list[str] = Field(default_factory=list)
    cart_items_count: int = 0
    last_agent_used: str = ""
    current_sentiment: str = "neutral"
    started_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


class MemorySnapshot(BaseModel):
    """صورة كاملة للذاكرة — بتتحمل أول المحادثة."""
    preferences: UserPreferences = Field(default_factory=UserPreferences)
    recent_episodes: list[ConversationEpisode] = Field(default_factory=list)
    session: Optional[SessionContext] = None
    conversation_count: int = 0

    def to_context_string(self) -> str:
        """تحويل الذاكرة لنص سياق يتقدم للوكلاء."""
        parts = []

        # التفضيلات
        if self.preferences.favorite_categories:
            parts.append(f"الفئات المفضلة: {', '.join(self.preferences.favorite_categories)}")
        if self.preferences.interests:
            parts.append(f"الاهتمامات: {', '.join(self.preferences.interests)}")
        if self.preferences.price_range != "غير محدد":
            parts.append(f"نطاق السعر: {self.preferences.price_range}")

        # الحلقات السابقة
        if self.recent_episodes:
            parts.append("محادثات سابقة:")
            for ep in self.recent_episodes[:3]:
                parts.append(f"  - {ep.summary}")

        # الجلسة الحالية
        if self.session and self.session.topics_discussed:
            parts.append(f"مواضيع الجلسة الحالية: {', '.join(self.session.topics_discussed)}")

        return "\n".join(parts) if parts else "لا توجد معلومات سابقة عن هذا المستخدم."
