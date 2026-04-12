"""
Web Search Tools using Tavily API.
"""
from langchain_core.tools import tool
from config import TAVILY_API_KEY


@tool
async def web_search(query: str, topic: str = "general") -> str:
    """Search the web for information about Egyptian history, artifacts, or tourism.
    Use this when local knowledge base doesn't have enough information."""
    try:
        from tavily import TavilyClient
        client = TavilyClient(api_key=TAVILY_API_KEY)
        response = client.search(
            query=f"Egyptian history tourism {query}",
            search_depth="advanced",
            max_results=5,
            include_answer=True,
        )

        answer = response.get("answer", "")
        results = response.get("results", [])
        sources = [r.get("url", "") for r in results[:3]]

        output = ""
        if answer:
            output += f"📝 الإجابة: {answer}\n\n"

        if results:
            output += "📚 المصادر:\n"
            for r in results[:3]:
                output += f"- {r.get('title', '')}: {r.get('content', '')[:200]}...\n"
                output += f"  🔗 {r.get('url', '')}\n"

        return output or "لم يتم العثور على نتائج."
    except Exception as e:
        return f"⚠️ خطأ في البحث: {str(e)}"


@tool
async def web_search_egyptian_history(query: str) -> str:
    """Search specifically for Egyptian history and archaeology information."""
    result = await web_search.ainvoke({
        "query": f"Ancient Egypt pharaoh archaeology {query}",
        "topic": "history"
    })
    return result


@tool
async def web_extract_url(url: str) -> str:
    """Extract and read content from a specific web URL."""
    try:
        from tavily import TavilyClient
        client = TavilyClient(api_key=TAVILY_API_KEY)
        response = client.extract(urls=[url])
        results = response.get("results", [])
        if results:
            return results[0].get("raw_content", "")[:2000]
        return "لم يتم استخراج محتوى."
    except Exception as e:
        return f"⚠️ خطأ: {str(e)}"


WEB_TOOLS = [web_search, web_search_egyptian_history, web_extract_url]
