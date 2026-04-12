"""
🧪 اختبارات Supervisor Routing
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.supervisor import _keyword_routing, _parse_agent_response


class TestKeywordRouting:
    """اختبارات التوجيه بالكلمات المفتاحية."""

    # --- Product Agent ---
    def test_product_arabic(self):
        assert _keyword_routing("عايز أشتري هدية") == "product_agent"

    def test_product_english(self):
        assert _keyword_routing("I want to buy a gift") == "product_agent"

    def test_product_price(self):
        assert _keyword_routing("كام سعر التمثال ده؟") == "product_agent"

    # --- History Agent ---
    def test_history_pharaoh(self):
        assert _keyword_routing("احكيلي عن توت عنخ آمون") == "history_agent"

    def test_history_pyramid(self):
        assert _keyword_routing("إيه تاريخ الأهرام؟") == "history_agent"

    def test_history_english(self):
        assert _keyword_routing("Tell me about the pharaohs") == "history_agent"

    def test_history_museum(self):
        assert _keyword_routing("عايز أزور المتحف") == "history_agent"

    # --- Cart Agent ---
    def test_cart_add(self):
        assert _keyword_routing("أضف المنتج للسلة") == "cart_agent"

    def test_cart_view(self):
        assert _keyword_routing("عرض السلة") == "cart_agent"

    def test_cart_coupon(self):
        assert _keyword_routing("في كوبون خصم؟") == "cart_agent"

    # --- Tour Guide Agent ---
    def test_tour_bazaar(self):
        assert _keyword_routing("فين أقرب بازار؟") == "tour_guide_agent"

    def test_tour_visit(self):
        assert _keyword_routing("عايز أزور أسوان") == "tour_guide_agent"

    # --- Web Research Agent ---
    def test_web_search(self):
        assert _keyword_routing("ابحث عن أخبار السياحة") == "web_research_agent"

    # --- Personalization Agent ---
    def test_personalization(self):
        assert _keyword_routing("اقترح حاجات تناسبني") == "personalization_agent"

    # --- General (لا تطابق) ---
    def test_general_fallback(self):
        """سؤال عام بدون كلمات مفتاحية → يرجع None (يحتاج LLM)."""
        assert _keyword_routing("مرحبا") is None

    def test_general_unrelated(self):
        """سؤال غير مرتبط → None."""
        assert _keyword_routing("ممكن تساعدني في الرياضيات") is None


class TestParseAgentResponse:
    """اختبارات تحليل رد المنسق."""

    def test_valid_json(self):
        assert _parse_agent_response('{"agent": "history_agent"}') == "history_agent"

    def test_json_in_code_block(self):
        assert _parse_agent_response('```json\n{"agent": "product_agent"}\n```') == "product_agent"

    def test_invalid_agent(self):
        assert _parse_agent_response('{"agent": "unknown_agent"}') == "general_agent"

    def test_invalid_json(self):
        assert _parse_agent_response("this is not json") == "general_agent"

    def test_empty_response(self):
        assert _parse_agent_response("") == "general_agent"
