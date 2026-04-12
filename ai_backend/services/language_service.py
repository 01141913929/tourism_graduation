"""
🌍 Language Detection — كشف لغة المستخدم (فوري بدون LLM)
"""
import re


def detect_language(text: str) -> str:
    """كشف لغة النص — 'ar' أو 'en'. فوري بدون API."""
    if not text or not text.strip():
        return "ar"

    # إزالة الإيموجي والأرقام والرموز
    cleaned = re.sub(r'[^\w\s]', '', text)
    cleaned = re.sub(r'\d+', '', cleaned)
    cleaned = cleaned.strip()

    if not cleaned:
        return "ar"

    # حساب عدد الحروف العربية vs اللاتينية
    arabic_chars = len(re.findall(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]', cleaned))
    latin_chars = len(re.findall(r'[a-zA-Z]', cleaned))

    total = arabic_chars + latin_chars
    if total == 0:
        return "ar"

    # لو أكتر من 40% لاتيني → إنجليزي
    if latin_chars / total > 0.4:
        return "en"

    return "ar"


def get_language_instruction(lang: str) -> str:
    """تعليمات اللغة اللي تتضاف للبرومبت."""
    if lang == "en":
        return (
            "\n\n🌍 LANGUAGE: The user is writing in English. "
            "You MUST respond entirely in English. "
            "Be friendly and use a warm, welcoming tone. "
            "Use emojis moderately."
        )
    return ""  # العربي هو الافتراضي — مش محتاج تعليمات
