"""
🧬 Semantic Memory — الذاكرة الدلالية (طويلة المدى)
بتتعلم تفضيلات المستخدم وبتحدّثها مع كل محادثة.
مخزنة في AWS DynamoDB وبتستمر بين الجلسات.
"""
import logging
from services.gemini_service import get_llm
from memory.aws_memory import get_user_preferences, save_user_preferences
from models.memory import UserPreferences

logger = logging.getLogger(__name__)


# ============================================================
# تحميل التفضيلات
# ============================================================

async def load_preferences(user_id: str) -> UserPreferences:
    """تحميل تفضيلات المستخدم من DynamoDB."""
    if not user_id:
        return UserPreferences()

    prefs_data = get_user_preferences(user_id) or {}

    return UserPreferences(
        favorite_categories=prefs_data.get("favorite_categories", []),
        price_range=prefs_data.get("price_range", "غير محدد"),
        preferred_language=prefs_data.get("preferred_language", "ar"),
        interests=prefs_data.get("interests", []),
        sentiment_history=prefs_data.get("sentiment_history", []),
        favorite_eras=prefs_data.get("favorite_eras", []),
        visited_bazaars=prefs_data.get("visited_bazaars", []),
        purchased_categories=prefs_data.get("purchased_categories", []),
    )


async def save_preferences(user_id: str, preferences: UserPreferences):
    """حفظ تفضيلات المستخدم في DynamoDB."""
    if not user_id:
        return

    prefs_dict = preferences.model_dump()
    save_user_preferences(user_id, prefs_dict)


# ============================================================
# تعلم التفضيلات
# ============================================================

async def learn_from_conversation(user_id: str, conversation_text: str,
                                   current_prefs: UserPreferences) -> UserPreferences:
    """تحليل المحادثة واستخراج تفضيلات جديدة."""
    if not user_id or not conversation_text:
        return current_prefs

    llm = get_llm(temperature=0.1)

    prompt = f"""حلل هذه المحادثة واستخرج تفضيلات المستخدم.

التفضيلات الحالية:
- الفئات المفضلة: {', '.join(current_prefs.favorite_categories) or 'غير محدد'}
- الاهتمامات: {', '.join(current_prefs.interests) or 'غير محدد'}
- نطاق السعر: {current_prefs.price_range}

المحادثة:
{conversation_text[:2000]}

استخرج التفضيلات الجديدة بهذا التنسيق:
CATEGORIES: فئة1, فئة2 (أو SAME لو ماتغيرتش)
INTERESTS: اهتمام1, اهتمام2 (أو SAME)
PRICE_RANGE: رخيص/متوسط/غالي (أو SAME)
ERAS: عصر1, عصر2 (أو SAME)"""

    try:
        response = await llm.ainvoke(prompt)
        text = response.content.strip()

        # تحليل الرد
        for line in text.split("\n"):
            line = line.strip()
            if line.startswith("CATEGORIES:") and "SAME" not in line:
                cats = [c.strip() for c in line.replace("CATEGORIES:", "").split(",") if c.strip()]
                if cats:
                    for cat in cats:
                        if cat not in current_prefs.favorite_categories:
                            current_prefs.favorite_categories.append(cat)

            elif line.startswith("INTERESTS:") and "SAME" not in line:
                interests = [i.strip() for i in line.replace("INTERESTS:", "").split(",") if i.strip()]
                if interests:
                    for interest in interests:
                        if interest not in current_prefs.interests:
                            current_prefs.interests.append(interest)

            elif line.startswith("PRICE_RANGE:") and "SAME" not in line:
                price = line.replace("PRICE_RANGE:", "").strip()
                if price:
                    current_prefs.price_range = price

            elif line.startswith("ERAS:") and "SAME" not in line:
                eras = [e.strip() for e in line.replace("ERAS:", "").split(",") if e.strip()]
                if eras:
                    for era in eras:
                        if era not in current_prefs.favorite_eras:
                            current_prefs.favorite_eras.append(era)

    except Exception as e:
        logger.warning(f"خطأ في تعلم التفضيلات: {e}")

    return current_prefs


# ============================================================
# سياق التفضيلات للوكلاء
# ============================================================

def get_preferences_context(preferences: UserPreferences) -> str:
    """بناء نص سياق التفضيلات — يتقدم للوكلاء."""
    parts = ["👤 معلومات عن المستخدم:"]

    if preferences.favorite_categories:
        parts.append(f"  - الفئات المفضلة: {', '.join(preferences.favorite_categories)}")
    if preferences.interests:
        parts.append(f"  - الاهتمامات: {', '.join(preferences.interests)}")
    if preferences.price_range != "غير محدد":
        parts.append(f"  - نطاق السعر: {preferences.price_range}")
    if preferences.favorite_eras:
        parts.append(f"  - العصور المفضلة: {', '.join(preferences.favorite_eras)}")
    if preferences.visited_bazaars:
        parts.append(f"  - بازارات زارها: {', '.join(preferences.visited_bazaars[:3])}")

    if len(parts) == 1:
        return ""  # لو مفيش تفضيلات

    return "\n".join(parts)


async def update_sentiment(user_id: str, sentiment: str):
    """تحديث سجل المشاعر."""
    if not user_id:
        return

    prefs = await load_preferences(user_id)
    prefs.sentiment_history.append(sentiment)
    # نحتفظ بآخر 20 مشاعر فقط
    prefs.sentiment_history = prefs.sentiment_history[-20:]
    await save_preferences(user_id, prefs)
