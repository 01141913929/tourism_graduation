"""
🧠 AgentState — تعريف حالة الجراف الرئيسية
كل المعلومات اللي بتتنقل بين العقد (nodes) في LangGraph

✅ محسّن مع:
- current_viewed_items: تمرير سياق المنتجات المعروضة بين الوكلاء (Context Hand-off)
- last_search_query: آخر استعلام بحث
- last_tool_results: نتائج الأدوات الأخيرة
"""
import time
from typing import TypedDict, Annotated
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages


class AgentState(TypedDict):
    """الحالة المركزية للنظام — بتتشارك بين كل الوكلاء."""

    # === الرسائل ===
    messages: Annotated[list[BaseMessage], add_messages]

    # === معرفات الجلسة ===
    session_id: str
    user_id: str

    # === حالة التوجيه ===
    current_agent: str          # اسم الوكيل الحالي
    agent_output: str           # مخرج الوكيل

    # === الرد النهائي ===
    final_response: str
    cards: list[dict]           # Rich cards (منتجات/آثار/بازارات)
    quick_actions: list[dict]   # أزرار إجراءات سريعة
    sources: list[str]          # مصادر (لو استخدم بحث الويب)

    # === الذاكرة والسياق ===
    chat_history: list[BaseMessage] # رسائل المحادثة السابقة
    memory_context: str         # سياق من الذاكرة (ملخصات + تفضيلات)
    conversation_summary: str   # ملخص المحادثة الحالية

    # === التخصيص ===
    sentiment: str              # مزاج المستخدم (positive/neutral/negative/curious)
    proactive_suggestions: list[dict]  # اقتراحات تلقائية
    user_preferences: dict      # تفضيلات المستخدم المحملة
    user_language: str          # لغة المستخدم: "ar" أو "en"

    # === التتبع والأداء ===
    start_time: float           # وقت بدء المعالجة — لحساب الـ latency
    error_count: int            # عدد الأخطاء في هذه الدورة
    last_agent_used: str        # آخر وكيل استُخدم — للـ follow-up detection

    # === Context Hand-off (تمرير السياق بين الوكلاء) ===
    current_viewed_items: list[dict]  # المنتجات المعروضة حالياً أمام المستخدم
    last_search_query: str            # آخر استعلام بحث تم تنفيذه
    last_tool_results: list[dict]     # نتائج الأدوات الأخيرة (خام)
