import asyncio
from core.langfuse_config import get_langfuse_handler
from langchain_core.messages import HumanMessage
from graph.workflow import get_workflow

async def test_langfuse():
    print("Testing Langfuse Integration...")
    langfuse_handler = get_langfuse_handler()
    config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}
    print(f"Has Langfuse Handler: {bool(langfuse_handler)}")

    graph = get_workflow()
    initial_state = {
        "messages": [HumanMessage(content="مرحبا، من أنت؟")],
        "session_id": "test_langfuse_session",
        "user_id": "test_user",
        "current_agent": "",
        "agent_output": "",
        "final_response": "",
        "cards": [],
        "quick_actions": [],
        "sources": [],
        "chat_history": [],
        "memory_context": "",
        "conversation_summary": "",
        "sentiment": "neutral",
        "proactive_suggestions": [],
        "user_preferences": {},
        "user_language": "ar",
        "start_time": 0,
        "error_count": 0,
        "last_agent_used": "",
        "current_viewed_items": [],
        "last_search_query": "",
        "last_tool_results": [],
    }

    print("Running graph...")
    try:
        async for event in graph.astream_events(initial_state, version="v2", config=config):
            if event["event"] == "on_chat_model_stream":
                pass
    except Exception as e:
        print(f"Error: {e}")

    if langfuse_handler:
        print("Flushing Langfuse...")
        langfuse_handler.flush()
    print("Done")

if __name__ == "__main__":
    asyncio.run(test_langfuse())
