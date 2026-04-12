"""
🧪 اختبارات Tool Executor
"""
import sys
import os
import asyncio
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from langchain_core.messages import AIMessage, ToolMessage
from langchain_core.tools import tool
from agents.tool_executor import run_agent_with_tools, _summarize_args


# === أدوات وهمية للاختبار ===

@tool
async def mock_search(query: str) -> str:
    """Mock search tool."""
    return f"نتائج البحث عن: {query}"


@tool
async def mock_add_to_cart(product_id: str) -> str:
    """Mock add to cart."""
    return f"تمت إضافة المنتج {product_id}"


@tool
async def mock_failing_tool(query: str) -> str:
    """Mock tool that fails."""
    raise Exception("Database connection error")


# === الاختبارات ===

class TestSummarizeArgs:
    def test_simple_args(self):
        result = _summarize_args({"query": "test"})
        assert "query=test" in result

    def test_long_value(self):
        result = _summarize_args({"query": "a" * 50})
        assert "..." in result

    def test_empty_args(self):
        assert _summarize_args({}) == ""


class TestRunAgentWithTools:

    @pytest.mark.asyncio
    async def test_no_tools_direct_call(self):
        """بدون أدوات → استدعاء مباشر."""
        mock_llm = AsyncMock()
        mock_llm.ainvoke.return_value = MagicMock(content="رد مباشر")

        result = await run_agent_with_tools(
            llm=mock_llm,
            tools=[],
            system_prompt="أنت مساعد",
            user_message="مرحبا",
        )
        assert result == "رد مباشر"

    @pytest.mark.asyncio
    async def test_with_tools_no_tool_call(self):
        """مع أدوات لكن LLM مش بيطلب أداة → رد مباشر."""
        mock_response = MagicMock()
        mock_response.tool_calls = []
        mock_response.content = "رد بدون أدوات"

        mock_llm = MagicMock()
        mock_bound = AsyncMock()
        mock_bound.ainvoke.return_value = mock_response
        mock_llm.bind_tools.return_value = mock_bound

        result = await run_agent_with_tools(
            llm=mock_llm,
            tools=[mock_search],
            system_prompt="أنت مساعد",
            user_message="مرحبا",
        )
        assert result == "رد بدون أدوات"

    @pytest.mark.asyncio
    async def test_with_tool_call_and_response(self):
        """LLM يطلب أداة → تنفيذ → رد نهائي."""
        # أول استدعاء: LLM يطلب أداة
        tool_call_response = MagicMock()
        tool_call_response.tool_calls = [{
            "name": "mock_search",
            "args": {"query": "أهرامات"},
            "id": "call_1",
        }]
        tool_call_response.content = ""

        # ثاني استدعاء: LLM يرد النهائي
        final_response = MagicMock()
        final_response.tool_calls = []
        final_response.content = "الأهرامات هي واحدة من عجائب الدنيا السبع!"

        mock_llm = MagicMock()
        mock_bound = AsyncMock()
        mock_bound.ainvoke.side_effect = [tool_call_response, final_response]
        mock_llm.bind_tools.return_value = mock_bound

        result = await run_agent_with_tools(
            llm=mock_llm,
            tools=[mock_search],
            system_prompt="أنت مؤرخ",
            user_message="احكيلي عن الأهرامات",
        )
        assert "الأهرامات" in result


class TestToolExecutorEdgeCases:

    @pytest.mark.asyncio
    async def test_timeout_handling(self):
        """التعامل مع Timeout."""
        mock_llm = MagicMock()
        mock_bound = AsyncMock()

        async def slow_invoke(*args, **kwargs):
            await asyncio.sleep(10)

        mock_bound.ainvoke = slow_invoke
        mock_llm.bind_tools.return_value = mock_bound

        result = await run_agent_with_tools(
            llm=mock_llm,
            tools=[mock_search],
            system_prompt="أنت مساعد",
            user_message="تست",
            timeout=0.1,
        )
        assert "عذراً" in result
