"""
🧪 اختبارات كشف اللغة (Language Detection)
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.language_service import detect_language, get_language_instruction


class TestDetectLanguage:
    # --- العربية ---
    def test_arabic_text(self):
        assert detect_language("عايز أشتري هدية حلوة") == "ar"

    def test_arabic_with_emoji(self):
        assert detect_language("مرحبا 😊 كيف الحال؟") == "ar"

    def test_arabic_question(self):
        assert detect_language("إيه أحسن بازار في القاهرة؟") == "ar"

    # --- الإنجليزية ---
    def test_english_text(self):
        assert detect_language("I want to visit the pyramids") == "en"

    def test_english_question(self):
        assert detect_language("What are the best souvenirs from Egypt?") == "en"

    # --- حالات خاصة ---
    def test_empty_string(self):
        assert detect_language("") == "ar"

    def test_only_emoji(self):
        assert detect_language("😍🤩👍") == "ar"

    def test_only_numbers(self):
        assert detect_language("12345") == "ar"

    def test_mixed_mostly_arabic(self):
        assert detect_language("عايز أعرف معلومات عن pyramids") == "ar"

    def test_mixed_mostly_english(self):
        assert detect_language("I want to buy هدية from Cairo") == "en"


class TestGetLanguageInstruction:
    def test_english_instruction(self):
        instruction = get_language_instruction("en")
        assert "English" in instruction
        assert len(instruction) > 0

    def test_arabic_no_instruction(self):
        instruction = get_language_instruction("ar")
        assert instruction == ""

    def test_unknown_language(self):
        instruction = get_language_instruction("fr")
        assert instruction == ""
