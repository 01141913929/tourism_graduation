"""
Pydantic models for chat API requests and responses.
"""
from pydantic import BaseModel, Field
from typing import Optional


class ChatRequest(BaseModel):
    """Incoming chat message from Flutter."""
    message: str = Field(..., description="User's message text")
    session_id: str = Field(..., description="Unique session identifier")
    user_id: Optional[str] = Field(None, description="Firebase user ID")
    latitude: Optional[float] = Field(None, description="User's latitude")
    longitude: Optional[float] = Field(None, description="User's longitude")


class CardAction(BaseModel):
    """An action button on a rich card."""
    label: str
    action: str        # "add_to_cart", "navigate", "web_link", "send_message"
    params: dict = {}


class ProductCardData(BaseModel):
    """بيانات كارت منتج منظمة — للفرونت إند."""
    product_id: str = ""
    title: str = ""
    price: float = 0.0
    old_price: Optional[float] = None
    image_url: str = ""
    category: str = ""
    bazaar_name: str = ""
    rating: float = 0.0
    review_count: int = 0


class RichCard(BaseModel):
    """A rich card in the AI response (product, artifact, bazaar)."""
    type: str          # "product_card", "artifact", "bazaar", "cart_summary"
    data: dict
    actions: list[CardAction] = []


class QuickAction(BaseModel):
    """A quick action button."""
    label: str
    message: str       # Message to send when tapped


class ChatResponse(BaseModel):
    """AI response sent back to Flutter."""
    text: str = Field(..., description="Main response text")
    cards: list[RichCard] = Field(default_factory=list)
    quick_actions: list[QuickAction] = Field(default_factory=list)
    session_id: str = ""
    sources: list[str] = Field(default_factory=list, description="Web sources if used")
    agent_used: str = ""
    sentiment: str = "neutral"
