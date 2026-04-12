"""
🔀 Graph Edges — حواف التوجيه في الجراف
بتحدد المسار بين العقد
"""
from graph.state import AgentState


# كل الوكلاء المتاحين
VALID_AGENTS = [
    "commerce_agent",
    "explorer_agent",
    "assistant_agent",
    "personalization_agent",
]


def route_to_agent(state: AgentState) -> str:
    """توجيه مشروط من المنسق للوكيل المختار."""
    agent = state.get("current_agent", "assistant_agent")

    if agent not in VALID_AGENTS:
        return "assistant_agent"

    return agent


def get_agent_routing_map() -> dict[str, str]:
    """خريطة التوجيه — بتتدى لـ add_conditional_edges."""
    return {agent: agent for agent in VALID_AGENTS}
