"""
📦 Structured Output Models — نماذج Pydantic للمدخلات والمخرجات المنظمة
كل بيانات تمر بين الوكلاء لازم يكون ليها نموذج واضح ومُصدَّق.
"""
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


# ============================================================
# 🏷️ Product Card — الوحدة الأساسية لعرض المنتجات
# ============================================================

class ProductCard(BaseModel):
    """كارت منتج منظم — يُستخدم في العرض وفي تمرير السياق بين الوكلاء."""
    index: int = Field(..., ge=1, description="ترتيب المنتج في القائمة (1-based)")
    product_id: str = Field(..., min_length=1, description="معرّف المنتج في Aurora")
    name_ar: str = Field(..., min_length=1, description="اسم المنتج بالعربية")
    name_en: str = Field(default="", description="اسم المنتج بالإنجليزية")
    price: float = Field(..., ge=0, description="السعر بالجنيه المصري")
    old_price: Optional[float] = Field(None, ge=0, description="السعر قبل الخصم")
    category: str = Field(default="", description="فئة المنتج")
    bazaar_name: str = Field(default="", description="اسم البازار")
    rating: float = Field(default=0.0, ge=0, le=5, description="التقييم من 5")
    review_count: int = Field(default=0, ge=0, description="عدد التقييمات")
    image_url: str = Field(default="", description="رابط صورة المنتج")
    material: str = Field(default="", description="المادة المصنوع منها")
    description_ar: str = Field(default="", description="وصف مختصر بالعربية")

    def to_display_text(self) -> str:
        """تنسيق المنتج كنص مقروء للعرض."""
        old = f" ~~{self.old_price}~~ ج" if self.old_price else ""
        lines = [
            f"{self.index}. 🏷️ **{self.name_ar}**",
            f"   💰 السعر: {self.price} جنيه{old}",
        ]
        if self.category:
            lines.append(f"   📁 القسم: {self.category}")
        if self.bazaar_name:
            lines.append(f"   🏪 بازار: {self.bazaar_name}")
        if self.rating > 0:
            lines.append(f"   ⭐ التقييم: {self.rating}/5")
        if self.image_url:
            lines.append(f"   🖼️ ![{self.name_ar}]({self.image_url})")
        lines.append(f"   🆔 [ID:{self.product_id}]")
        return "\n".join(lines)

    def to_cart_context_line(self) -> str:
        """سطر واحد مختصر لسياق السلة."""
        return f"  {self.index}. {self.name_ar} — ID: {self.product_id} — السعر: {self.price} ج"

    def to_rich_card(self) -> dict:
        """تحويل لكارت Rich Card للفرونت إند."""
        return {
            "type": "product_card",
            "data": {
                "product_id": self.product_id,
                "title": self.name_ar,
                "price": self.price,
                "old_price": self.old_price,
                "image_url": self.image_url,
                "category": self.category,
                "bazaar_name": self.bazaar_name,
                "rating": self.rating,
                "review_count": self.review_count,
            },
            "actions": [
                {
                    "label": "🛒 أضف للسلة",
                    "action": "add_to_cart",
                    "params": {"product_id": self.product_id},
                },
                {
                    "label": "📋 تفاصيل",
                    "action": "send_message",
                    "params": {"message": f"تفاصيل المنتج {self.product_id}"},
                },
            ],
        }


# ============================================================
# 📋 Viewed Items Context — سياق المنتجات المعروضة
# ============================================================

class ViewedItemsContext(BaseModel):
    """المنتجات التي تم عرضها للمستخدم — يكتبها الوكيل المُنتِج ويقرأها الوكيل التالي."""
    items: list[ProductCard] = Field(default_factory=list, description="قائمة المنتجات المعروضة")
    search_query: str = Field(default="", description="استعلام البحث الأصلي")
    total_found: int = Field(default=0, ge=0, description="إجمالي المنتجات الموجودة")

    def to_cart_context(self) -> str:
        """تحويل لسياق مقروء لوكيل السلة."""
        if not self.items:
            return ""
        lines = ["⚠️ المنتجات المعروضة حالياً أمام المستخدم:"]
        for item in self.items:
            lines.append(item.to_cart_context_line())
        lines.append("")
        lines.append("عندما يقول 'الأول' أو 'التاني' أو 'ده'، يقصد من القائمة أعلاه.")
        lines.append("استخدم الـ product_id مباشرة مع أداة add_to_cart.")
        return "\n".join(lines)

    def to_rich_cards(self) -> list[dict]:
        """تحويل لقائمة Rich Cards."""
        return [item.to_rich_card() for item in self.items]

    def resolve_index(self, index: int) -> Optional[ProductCard]:
        """حل مرجع بالترتيب (مثل 'التاني' = index 2)."""
        for item in self.items:
            if item.index == index:
                return item
        return None


# ============================================================
# 🎯 Supervisor Decision — قرار المنسق
# ============================================================

class ValidAgent(str, Enum):
    """الوكلاء المتاحون في النظام (Consolidated Architecture)."""
    COMMERCE = "commerce_agent"
    EXPLORER = "explorer_agent"
    ASSISTANT = "assistant_agent"
    PERSONALIZATION = "personalization_agent"


class SupervisorDecision(BaseModel):
    """قرار المنسق — لمين يوجه الطلب ولماذا."""
    agent: ValidAgent = Field(default=ValidAgent.ASSISTANT, description="الوكيل المختار")
    reason: str = Field(default="", description="سبب الاختيار")
    is_followup: bool = Field(default=False, description="هل هي متابعة لموضوع سابق")
    confidence: float = Field(default=0.8, ge=0.0, le=1.0, description="نسبة الثقة")

    @property
    def agent_name(self) -> str:
        return self.agent.value


# ============================================================
# 🏺 Artifact Card — كارت أثر تاريخي
# ============================================================

class ArtifactCard(BaseModel):
    """كارت أثر تاريخي منظم."""
    artifact_id: str = Field(..., min_length=1)
    name_ar: str = Field(..., min_length=1)
    name_en: str = ""
    era: str = ""
    location: str = ""
    description_ar: str = ""
    image_url: str = ""

    def to_rich_card(self) -> dict:
        return {
            "type": "artifact",
            "data": {
                "artifact_id": self.artifact_id,
                "title": f"🏺 {self.name_ar}",
                "era": self.era,
                "location": self.location,
                "description": self.description_ar[:150],
                "image_url": self.image_url,
            },
            "actions": [
                {"label": "📍 الموقع", "action": "navigate", "params": {"location": self.location}},
                {"label": "🛍️ هدايا متعلقة", "action": "send_message", "params": {"message": f"منتجات متعلقة بـ {self.name_ar}"}},
            ],
        }


# ============================================================
# 🏪 Bazaar Card — كارت بازار
# ============================================================

class BazaarCard(BaseModel):
    """كارت بازار منظم."""
    bazaar_id: str = Field(..., min_length=1)
    name_ar: str = Field(..., min_length=1)
    name_en: str = ""
    area: str = ""
    address: str = ""
    is_open: bool = False
    rating: float = 0.0
    distance_km: Optional[float] = None
    image_url: str = ""

    def to_rich_card(self) -> dict:
        status = "مفتوح ✅" if self.is_open else "مغلق ❌"
        dist = f" — {self.distance_km} كم" if self.distance_km is not None else ""
        return {
            "type": "bazaar",
            "data": {
                "bazaar_id": self.bazaar_id,
                "title": f"🏪 {self.name_ar}",
                "area": self.area,
                "address": self.address,
                "status": status,
                "rating": self.rating,
                "distance": dist,
                "image_url": self.image_url,
            },
            "actions": [
                {"label": "📍 الخريطة", "action": "navigate", "params": {"location": self.name_ar}},
                {"label": "🛍️ منتجات البازار", "action": "send_message", "params": {"message": f"منتجات بازار {self.name_ar}"}},
            ],
        }


# ============================================================
# 🛒 Cart Action Result — نتيجة عملية السلة
# ============================================================

class CartActionType(str, Enum):
    ADDED = "added"
    REMOVED = "removed"
    CLEARED = "cleared"
    VIEWED = "viewed"
    COUPON_APPLIED = "coupon_applied"


class CartActionResult(BaseModel):
    """نتيجة عملية على السلة — منظمة ومُصدَّقة."""
    action: CartActionType
    product_id: Optional[str] = None
    product_name: Optional[str] = None
    quantity: int = Field(default=1, ge=0)
    total_items: int = Field(default=0, ge=0)
    total_price: float = Field(default=0.0, ge=0)
    success: bool = True
    message: str = ""


# ============================================================
# 🔧 Helper: Parse product from DB dict
# ============================================================

def product_from_db(data: dict, index: int = 1) -> ProductCard:
    """تحويل بيانات Aurora/DB لنموذج ProductCard مُصدَّق."""
    return ProductCard(
        index=index,
        product_id=data.get("id", ""),
        name_ar=data.get("nameAr", data.get("name", "منتج")),
        name_en=data.get("nameEn", ""),
        price=float(data.get("price", 0)),
        old_price=float(data["oldPrice"]) if data.get("oldPrice") else None,
        category=data.get("category", ""),
        bazaar_name=data.get("bazaarName", ""),
        rating=float(data.get("rating", 0)),
        review_count=int(data.get("reviewCount", 0)),
        image_url=data.get("imageUrl", data.get("image", "")),
        material=data.get("material", ""),
        description_ar=data.get("descriptionAr", "")[:200],
    )
