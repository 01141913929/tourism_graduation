"""
🔗 Workflow — تجميع الجراف الرئيسي
ملف خفيف — كل المنطق في nodes.py و edges.py
✅ يدعم Reflection Node (قابلة للتعطيل من config.py)
"""
from langgraph.graph import StateGraph, END
from graph.state import AgentState
from graph.nodes import (
    memory_loader_node,
    supervisor_node,
    commerce_agent_node,
    explorer_agent_node,
    assistant_agent_node,
    personalization_agent_node,
    reflection_node,
    build_response_node,
    learn_preferences_node,
)
from graph.edges import route_to_agent, get_agent_routing_map
from config import ENABLE_REFLECTION


_compiled_graph = None


def create_workflow():
    """بناء وتجميع جراف LangGraph."""
    workflow = StateGraph(AgentState)

    # ============ إضافة العقد ============
    workflow.add_node("memory_loader", memory_loader_node)
    workflow.add_node("supervisor", supervisor_node)
    workflow.add_node("commerce_agent", commerce_agent_node)
    workflow.add_node("explorer_agent", explorer_agent_node)
    workflow.add_node("assistant_agent", assistant_agent_node)
    workflow.add_node("personalization_agent", personalization_agent_node)
    workflow.add_node("reflection", reflection_node)
    workflow.add_node("build_response", build_response_node)
    workflow.add_node("learn_preferences", learn_preferences_node)

    # ============ نقطة البداية ============
    workflow.set_entry_point("memory_loader")

    # memory_loader → supervisor
    workflow.add_edge("memory_loader", "supervisor")

    # ============ توجيه مشروط من المنسق ============
    workflow.add_conditional_edges(
        "supervisor",
        route_to_agent,
        get_agent_routing_map(),
    )

    # ============ الوكلاء → reflection → بناء الرد → تعلم → النهاية ============
    agents = [
        "commerce_agent", "explorer_agent", "assistant_agent",
        "personalization_agent",
    ]

    if ENABLE_REFLECTION:
        for agent in agents:
            workflow.add_edge(agent, "reflection")
        workflow.add_edge("reflection", "build_response")
        print("🔍 Reflection Node: مفعّلة")
    else:
        for agent in agents:
            workflow.add_edge(agent, "build_response")
        print("⏭️ Reflection Node: معطّلة")

    # build_response → learn_preferences → END
    workflow.add_edge("build_response", "learn_preferences")
    workflow.add_edge("learn_preferences", END)
    print("🧠 Learn Preferences Node: مفعّلة")

    # ============ تجميع ============
    graph = workflow.compile()
    print("✅ جراف LangGraph جاهز!")
    return graph


def get_workflow():
    """الحصول على الجراف المجمع (Singleton)."""
    global _compiled_graph
    if _compiled_graph is None:
        _compiled_graph = create_workflow()
    return _compiled_graph
