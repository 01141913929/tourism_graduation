"""
🧪 اختبارات نظام الذاكرة (Working Memory)
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from langchain_core.messages import HumanMessage, AIMessage
from memory.working_memory import (
    get_session, add_message, get_messages,
    get_conversation_context, get_conversation_text,
    get_summary, set_summary, clear_session,
    is_memory_loaded, mark_memory_loaded,
    set_long_term_context, get_long_term_context,
    update_session_metadata, get_session_summary,
    should_summarize, get_active_sessions_count,
    _sessions,
)


def _clean():
    """تنظيف الجلسات قبل كل اختبار."""
    _sessions.clear()


class TestGetSession:
    def test_creates_new_session(self):
        _clean()
        session = get_session("test_1")
        assert session is not None
        assert session["messages"] == []
        assert session["message_count"] == 0

    def test_returns_existing_session(self):
        _clean()
        s1 = get_session("test_2")
        s1["message_count"] = 5
        s2 = get_session("test_2")
        assert s2["message_count"] == 5


class TestAddMessage:
    def test_adds_message(self):
        _clean()
        add_message("s1", HumanMessage(content="مرحبا"))
        session = get_session("s1")
        assert len(session["messages"]) == 1
        assert session["message_count"] == 1

    def test_increments_count(self):
        _clean()
        add_message("s2", HumanMessage(content="أهلا"))
        add_message("s2", AIMessage(content="أهلا بيك"))
        session = get_session("s2")
        assert session["message_count"] == 2

    def test_trimming(self):
        """يقلّم الرسائل القديمة لو تجاوزت الحد."""
        _clean()
        for i in range(25):
            add_message("s3", HumanMessage(content=f"رسالة {i}"))
        session = get_session("s3")
        assert len(session["messages"]) <= 20
        assert session["message_count"] == 25  # العدّاد مستمر


class TestGetConversationContext:
    def test_empty_session(self):
        _clean()
        ctx = get_conversation_context("empty")
        assert ctx == ""

    def test_with_messages(self):
        _clean()
        add_message("ctx_test", HumanMessage(content="عايز أتسوق"))
        add_message("ctx_test", AIMessage(content="أهلاً! إيه اللي محتاجه؟"))
        ctx = get_conversation_context("ctx_test")
        assert "المستخدم" in ctx
        assert "المساعد" in ctx


class TestSummary:
    def test_set_and_get(self):
        _clean()
        set_summary("sum_test", "المستخدم سأل عن تماثيل")
        assert get_summary("sum_test") == "المستخدم سأل عن تماثيل"


class TestMemoryLoaded:
    def test_initial_state(self):
        _clean()
        assert not is_memory_loaded("ml_test")

    def test_mark_loaded(self):
        _clean()
        mark_memory_loaded("ml_test")
        assert is_memory_loaded("ml_test")


class TestLongTermContext:
    def test_set_and_get(self):
        _clean()
        set_long_term_context("lt_test", "حلقات سابقة", "تفضيلات")
        ep, prefs = get_long_term_context("lt_test")
        assert ep == "حلقات سابقة"
        assert prefs == "تفضيلات"


class TestSessionMetadata:
    def test_update_topic(self):
        _clean()
        update_session_metadata("meta_test", topics="تسوق")
        session = get_session("meta_test")
        assert "تسوق" in session["topics"]

    def test_no_duplicate_topics(self):
        _clean()
        update_session_metadata("meta_dup", topics="تاريخ")
        update_session_metadata("meta_dup", topics="تاريخ")
        session = get_session("meta_dup")
        assert session["topics"].count("تاريخ") == 1


class TestShouldSummarize:
    def test_at_threshold(self):
        assert should_summarize("any_session") is False  # session doesn't exist yet

    def test_at_15(self):
        _clean()
        session = get_session("sum15")
        session["message_count"] = 15
        assert should_summarize("sum15") is True

    def test_at_30(self):
        _clean()
        session = get_session("sum30")
        session["message_count"] = 30
        assert should_summarize("sum30") is True

    def test_at_10(self):
        _clean()
        session = get_session("sum10")
        session["message_count"] = 10
        assert should_summarize("sum10") is False


class TestClearSession:
    def test_clear(self):
        _clean()
        add_message("clear_test", HumanMessage(content="تست"))
        clear_session("clear_test")
        # بعد المسح — جلسة جديدة
        session = get_session("clear_test")
        assert session["message_count"] == 0


class TestActiveSessionsCount:
    def test_count(self):
        _clean()
        get_session("a1")
        get_session("a2")
        get_session("a3")
        assert get_active_sessions_count() == 3
