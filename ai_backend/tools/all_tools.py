"""
LangChain Tools for all agents.
These are @tool decorated functions that agents can call.
✅ محسّن مع تنسيق منظم ومتسق + [ID:xxx] tags لربط المنتجات بين الوكلاء
🟢 تمت ترقيته لاستخدام Aurora & DynamoDB (AWS Native) بدلاً من Firebase
"""
from langchain_core.tools import tool
from typing import Optional
from services import aws_db_service as db
from services.cache_service import get_cache
import logging

logger = logging.getLogger(__name__)


# ============================================================
# 🔧 Helper: تنسيق موحد للمنتجات
# ============================================================

def _format_product_entry(index: int, p: dict) -> str:
    """تنسيق موحد لعرض منتج — يُستخدم في كل الأدوات."""
    old = f" (بدلاً من {p.get('oldPrice')} ج)" if p.get("oldPrice") else ""
    img = p.get("imageUrl", p.get("image", ""))
    img_line = f"\n   🖼️ ![{p.get('nameAr', '')}]({img})" if img else ""
    return (
        f"{index}. 🏷️ **{p.get('nameAr', 'منتج')}**\n"
        f"   💰 السعر: {p.get('price', 0)} جنيه{old}\n"
        f"   📁 القسم: {p.get('category', '')}\n"
        f"   🏪 بازار: {p.get('bazaarName', '')}\n"
        f"   ⭐ التقييم: {p.get('rating', 0)}/5"
        f"{img_line}\n"
        f"   🆔 [ID:{p.get('id', '')}]"
    )


def _format_product_brief(index: int, p: dict) -> str:
    """تنسيق مختصر لمنتج (للقوائم الطويلة)."""
    img = p.get("imageUrl", p.get("image", ""))
    img_part = f" — 🖼️ ![{p.get('nameAr', '')}]({img})" if img else ""
    return (
        f"{index}. **{p.get('nameAr', 'منتج')}** — "
        f"{p.get('price', 0)} ج — "
        f"{p.get('category', '')}"
        f"{img_part} — "
        f"[ID:{p.get('id', '')}]"
    )


# ============================================================
# 🛍️ Product Tools
# ============================================================

@tool
async def search_products(query: str, category: Optional[str] = None,
                          min_price: Optional[float] = None, max_price: Optional[float] = None) -> str:
    """Search for products in Egyptian bazaars by description, category, or price range.
    Use this when the user asks about products, gifts, souvenirs, or shopping."""
    products = await db.search_products(
        query=query, category=category,
        min_price=min_price, max_price=max_price
    )
    if not products:
        return "لم يتم العثور على منتجات مطابقة."

    result_lines = [f"تم العثور على {len(products)} منتج:\n"]
    for i, p in enumerate(products[:5], 1):
        result_lines.append(_format_product_entry(i, p))
        result_lines.append("")  # سطر فاصل

    return "\n".join(result_lines)


@tool
async def get_product_details(product_id: str) -> str:
    """Get full details of a specific product by its ID."""
    p = await db.get_product_by_id(product_id)
    if not p:
        return f"لم يتم العثور على منتج بالمعرف {product_id}"

    img = p.get("imageUrl", p.get("image", ""))
    img_line = f"\n🖼️ ![{p.get('nameAr', '')}]({img})" if img else ""
    return (
        f"📦 **{p.get('nameAr', '')}** ({p.get('nameEn', '')})\n"
        f"💰 السعر: {p.get('price', 0)} جنيه\n"
        f"📝 الوصف: {p.get('descriptionAr', '')}\n"
        f"🏪 البازار: {p.get('bazaarName', '')}\n"
        f"📐 المقاسات: {', '.join(p.get('sizes', []))}\n"
        f"🔧 المادة: {p.get('material', '')}"
        f"{img_line}\n"
        f"⭐ التقييم: {p.get('rating', '')}/5 ({p.get('reviewCount', 0)} تقييم)\n"
        f"🆔 [ID:{p.get('id', '')}]"
    )


@tool
async def get_featured_products(limit: int = 5) -> str:
    """Get the featured/highlighted products. Use when user asks about popular or recommended items."""
    products = await db.get_featured_products(limit)
    if not products:
        return "لا توجد منتجات مميزة حالياً."

    result_lines = ["⭐ المنتجات المميزة:\n"]
    for i, p in enumerate(products, 1):
        result_lines.append(_format_product_entry(i, p))
        result_lines.append("")

    return "\n".join(result_lines)


@tool
async def get_products_by_category(category: str) -> str:
    """Get products filtered by category (تماثيل، بردي، مجوهرات، منسوجات، إلخ)."""
    products = await db.search_products(category=category)
    if not products:
        return f"لا توجد منتجات في فئة '{category}'."

    result_lines = [f"منتجات فئة '{category}':\n"]
    for i, p in enumerate(products[:8], 1):
        result_lines.append(_format_product_brief(i, p))

    return "\n".join(result_lines)


@tool
async def compare_products(product_id_1: str, product_id_2: str) -> str:
    """Compare two products side by side."""
    p1 = await db.get_product_by_id(product_id_1)
    p2 = await db.get_product_by_id(product_id_2)
    if not p1 or not p2:
        return "أحد المنتجات غير موجود."
    return (
        f"📊 مقارنة:\n\n"
        f"**{p1.get('nameAr', '')}** [ID:{p1.get('id', '')}]\n"
        f"- السعر: {p1.get('price', 0)} ج\n"
        f"- المادة: {p1.get('material', '')}\n"
        f"- التقييم: {p1.get('rating', '')}/5\n"
        f"- البازار: {p1.get('bazaarName', '')}\n\n"
        f"**{p2.get('nameAr', '')}** [ID:{p2.get('id', '')}]\n"
        f"- السعر: {p2.get('price', 0)} ج\n"
        f"- المادة: {p2.get('material', '')}\n"
        f"- التقييم: {p2.get('rating', '')}/5\n"
        f"- البازار: {p2.get('bazaarName', '')}"
    )


# ============================================================
# 🏺 Artifact Tools
# ============================================================

@tool
async def get_artifact_info(artifact_id: str) -> str:
    """Get detailed information about a museum artifact by its ID."""
    a = await db.get_artifact_by_id(artifact_id)
    if not a:
        return f"لم يتم العثور على أثر بالمعرف {artifact_id}"
    return (
        f"🏺 **{a.get('nameAr', '')}**\n"
        f"📝 {a.get('descriptionAr', '')}\n"
        f"📅 العصر: {a.get('era', '')}\n"
        f"📍 الموقع: {a.get('location', '')}\n"
        f"🆔 [ID:{a.get('id', '')}]"
    )


@tool
async def search_artifacts(query: str, era: str = None) -> str:
    """Search for museum artifacts by name, description, or historical era."""
    artifacts = await db.search_artifacts(query=query, era=era)
    if not artifacts:
        return "لم يتم العثور على آثار مطابقة."

    result_lines = [f"تم العثور على {len(artifacts)} قطعة:\n"]
    for i, a in enumerate(artifacts[:5], 1):
        result_lines.append(
            f"{i}. 🏺 **{a.get('nameAr', '')}** — العصر: {a.get('era', '')} — [ID:{a.get('id', '')}]"
        )

    return "\n".join(result_lines)


# ============================================================
# 🏪 Bazaar Tools
# ============================================================

@tool
async def get_nearby_bazaars(latitude: float, longitude: float, radius_km: float = 50) -> str:
    """Find bazaars near a location. Use when user asks about nearby shops or markets."""
    bazaars = await db.get_nearby_bazaars(latitude, longitude, radius_km)
    if not bazaars:
        return "لا توجد بازارات قريبة."

    result_lines = ["🏪 البازارات القريبة:\n"]
    for i, b in enumerate(bazaars[:5], 1):
        status = "مفتوح ✅" if b.get("isOpen") else "مغلق ❌"
        result_lines.append(
            f"{i}. 🏪 **{b.get('nameAr', '')}** — المسافة: {b.get('distance_km', '')} كم — "
            f"{status} — المواعيد: {b.get('workingHours', '')} — [ID:{b.get('id', '')}]"
        )

    return "\n".join(result_lines)


@tool
async def get_bazaar_details(bazaar_id: str) -> str:
    """Get full details of a specific bazaar."""
    b = await db.get_bazaar_by_id(bazaar_id)
    if not b:
        return f"لم يتم العثور على بازار بالمعرف {bazaar_id}"
    status = "مفتوح ✅" if b.get("isOpen") else "مغلق ❌"
    return (
        f"🏪 **{b.get('nameAr', '')}** ({b.get('nameEn', '')})\n"
        f"📝 {b.get('descriptionAr', '')}\n"
        f"📍 العنوان: {b.get('address', '')}\n"
        f"🕐 المواعيد: {b.get('workingHours', '')}\n"
        f"📞 الهاتف: {b.get('phone', '')}\n"
        f"⭐ التقييم: {b.get('rating', '')}/5 ({b.get('reviewCount', 0)} تقييم)\n"
        f"الحالة: {status}\n"
        f"🆔 [ID:{b.get('id', '')}]"
    )


@tool
async def get_bazaar_products(bazaar_id: str, limit: int = 5) -> str:
    """Get products available at a specific bazaar."""
    products = await db.search_products(bazaar_id=bazaar_id, limit=limit)
    if not products:
        return "لا توجد منتجات في هذا البازار."

    result_lines = ["🏪 منتجات البازار:\n"]
    for i, p in enumerate(products, 1):
        result_lines.append(_format_product_brief(i, p))

    return "\n".join(result_lines)


# ============================================================
# 🛒 Cart Tools (DynamoDB-backed — بيانات مستمرة)
# ============================================================

@tool
async def add_to_cart(product_id: str, quantity: int = 1, size: Optional[str] = None,
                      user_id: str = "default") -> str:
    """Add a product to the shopping cart. user_id should be the user's ID.
    product_id MUST be a real product ID from search results or context — never fabricate one."""
    if not product_id or product_id in ("default", "unknown", "null", "undefined"):
        return "❌ خطأ: معرف المنتج (product_id) غير صالح. استخدم search_products للعثور على المعرف الصحيح."

    product = await db.get_product_by_id(product_id)
    if not product:
        return (
            f"❌ المنتج غير موجود: {product_id}\n"
            f"💡 استخدم أداة search_products للبحث عن المنتج بالاسم أولاً."
        )

    sel_size = size or (product.get("sizes", [""])[0] if product.get("sizes") else "")
    cart_item = {
        "productId": product_id,
        "selectedSize": sel_size,
        "quantity": quantity,
    }

    await db.add_cart_item(user_id, cart_item)

    items = await db.get_cart_items(user_id)
    total_items = sum(it.get("quantity", 1) for it in items)

    img = product.get("imageUrl", product.get("image", ""))
    img_line = f"\n🖼️ ![{product.get('nameAr', '')}]({img})" if img else ""

    return (
        f"✅ تمت إضافة **{product.get('nameAr', '')}** للسلة! (الكمية: {quantity})\n"
        f"💰 السعر: {product.get('price', 0)} جنيه"
        f"{img_line}\n"
        f"🛒 السلة الآن: {total_items} منتجات\n"
        f"🆔 [ID:{product_id}]"
    )


@tool
async def remove_from_cart(item_index: int, user_id: str = "default") -> str:
    """Remove an item from the cart by its index (1-based). user_id = user ID."""
    items = await db.get_cart_items(user_id)
    idx = item_index - 1
    if 0 <= idx < len(items):
        pid = items[idx].get("productId", "")
        await db.remove_cart_item(user_id, idx)

        product = await db.get_product_by_id(pid)
        name = product.get("nameAr", "") if product else f"المنتج المحذوف ({pid})"

        # MED-07: Invalidate cache after cart mutation
        get_cache().invalidate(user_id)

        return f"✅ تم حذف **{name}** من السلة (العنصر رقم {item_index})."
    return f"❌ رقم العنصر {item_index} غير صحيح. السلة تحتوي على {len(items)} عناصر."


@tool
async def get_cart(user_id: str = "default") -> str:
    """View current shopping cart contents. user_id = user ID."""
    items = await db.get_cart_items(user_id)
    if not items:
        return "🛒 السلة فارغة."

    import asyncio
    product_tasks = [db.get_product_by_id(item.get("productId", "")) for item in items]
    products = await asyncio.gather(*product_tasks)

    result = ["🛒 **السلة:**\n"]
    total = 0
    for i, (item, product) in enumerate(zip(items, products), 1):
        pid = item.get("productId", "")
        qty = item.get("quantity", 1)
        if product:
            price = float(product.get("price", 0))
            subtotal = price * qty
            total += subtotal
            img = product.get("imageUrl", product.get("image", ""))
            img_part = f"\n   🖼️ ![{product.get('nameAr', '')}]({img})" if img else ""
            result.append(
                f"{i}. **{product.get('nameAr', '')}** — {price} ج × {qty} = {subtotal} ج"
                f"{img_part}\n"
                f"   🆔 [ID:{pid}]"
            )
        else:
            result.append(f"{i}. منتج محذوف ({pid})")

    result.append(f"\n💰 **المجموع: {total} جنيه**")
    return "\n".join(result)


@tool
async def get_cart_total(user_id: str = "default") -> str:
    """Get the total price of items in the cart. user_id = user ID."""
    items = await db.get_cart_items(user_id)
    if not items:
        return "💰 المجموع: 0 جنيه (السلة فارغة)"

    import asyncio
    product_tasks = [db.get_product_by_id(item.get("productId", "")) for item in items]
    products = await asyncio.gather(*product_tasks)

    total = 0
    for item, product in zip(items, products):
        if product:
            total += float(product.get("price", 0)) * item.get("quantity", 1)

    return f"💰 المجموع: {total} جنيه ({len(items)} منتجات)"


@tool
async def apply_coupon(coupon_code: str) -> str:
    """Apply a discount coupon code."""
    coupon = await db.validate_coupon(coupon_code)
    if not coupon:
        return f"❌ الكوبون '{coupon_code}' غير صالح أو منتهي."
    return (
        f"✅ تم تطبيق الكوبون '{coupon_code}'!\n"
        f"الخصم: {coupon.get('discountPercentage', coupon.get('discountAmount', 0))}%"
    )


@tool
async def check_available_coupons() -> str:
    """Check what discount coupons are currently available."""
    coupons = await db.get_available_coupons()
    if not coupons:
        return "لا توجد كوبونات متاحة حالياً."
    result = [f"- 🎟️ {c.get('code', '')} — خصم {c.get('discountPercentage', '')}%" for c in coupons]
    return "🎟️ الكوبونات المتاحة:\n" + "\n".join(result)


@tool
async def clear_cart(user_id: str = "default") -> str:
    """Clear all items from the cart. user_id = user ID."""
    if not user_id or user_id == "default":
        return "❌ لا يوجد معرف مستخدم."
    await db.clear_cart(user_id)
    # MED-07: Invalidate cache after cart mutation
    get_cache().invalidate(user_id)
    return "✅ تم تفريغ السلة."


# ============================================================
# 👤 User Memory Tools
# ============================================================

@tool
async def get_user_preferences(user_id: str) -> str:
    """Get the user's saved preferences and history."""
    if not user_id:
        return "لا يوجد معرف مستخدم."
    memory = await db.get_user_memory(user_id)
    prefs = memory.get("preferences", {})
    topics = memory.get("topics_discussed", [])
    count = memory.get("conversation_count", 0)
    return (
        f"👤 تفضيلات المستخدم:\n"
        f"- الفئات المفضلة: {', '.join(prefs.get('favorite_categories', ['غير محدد']))}\n"
        f"- نطاق السعر: {prefs.get('price_range', 'غير محدد')}\n"
        f"- المواضيع السابقة: {', '.join(topics[-5:]) if topics else 'لا يوجد'}\n"
        f"- عدد المحادثات: {count}"
    )


@tool
async def get_conversation_history(user_id: str) -> str:
    """Get summaries of previous conversations with this user."""
    if not user_id:
        return "لا يوجد معرف مستخدم."
    summaries = await db.get_conversation_summaries(user_id)
    if not summaries:
        return "لا توجد محادثات سابقة."
    result = [f"- {s}" for s in summaries]
    return "📋 ملخصات المحادثات السابقة:\n" + "\n".join(result)


# ============================================================
# Tool Collections for each agent
# ============================================================

PRODUCT_TOOLS = [
    search_products, get_product_details, get_featured_products,
    get_products_by_category, compare_products,
]

ARTIFACT_TOOLS = [
    get_artifact_info, search_artifacts,
]

BAZAAR_TOOLS = [
    get_nearby_bazaars, get_bazaar_details, get_bazaar_products,
]

CART_TOOLS = [
    add_to_cart, remove_from_cart, get_cart, get_cart_total,
    apply_coupon, check_available_coupons, clear_cart,
]

USER_TOOLS = [
    get_user_preferences, get_conversation_history,
]

# LOW-08 Fix: Use set() semantics to avoid duplicates
_all_tools_set = {}
for t in PRODUCT_TOOLS + ARTIFACT_TOOLS + BAZAAR_TOOLS + CART_TOOLS + USER_TOOLS:
    _all_tools_set[t.name] = t
ALL_TOOLS = list(_all_tools_set.values())
