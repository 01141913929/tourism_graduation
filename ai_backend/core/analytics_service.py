"""
📊 Core Analytics Service — Platform-level analytics for Admin Panel.
"""
import asyncio
import logging
from datetime import datetime, timedelta
from collections import defaultdict
from core.db_service import get_all_products, get_all_bazaars, get_all_orders, get_user_count

logger = logging.getLogger(__name__)


async def compute_platform_analytics(period: str = "month") -> dict:
    """Compute platform-wide analytics for admin dashboard."""
    days_map = {"week": 7, "month": 30, "quarter": 90, "year": 365}
    days = days_map.get(period, 30)

    orders, bazaars, products, user_count = await asyncio.gather(
        get_all_orders(days), get_all_bazaars(), get_all_products(), get_user_count()
    )

    total_revenue = 0.0
    daily_revenue: dict[str, float] = defaultdict(float)
    bazaar_revenue: dict[str, float] = defaultdict(float)
    bazaar_orders_count: dict[str, int] = defaultdict(int)
    status_counts: dict[str, int] = defaultdict(int)

    for order in orders:
        total = float(order.get("total", 0) or 0)
        status = order.get("status", "unknown")
        status_counts[status] += 1

        if status in ("delivered", "accepted"):
            total_revenue += total
            bid = order.get("bazaar_id", "unknown")
            bazaar_revenue[bid] += total
            bazaar_orders_count[bid] += 1

            created_at = order.get("created_at")
            if created_at:
                if hasattr(created_at, "strftime"):
                    day_key = created_at.strftime("%Y-%m-%d")
                else:
                    day_key = str(created_at)[:10]
                daily_revenue[day_key] += total

    # Category analysis
    category_revenue = defaultdict(float)
    product_map = {p["id"]: p for p in products}
    for order in orders:
        if order.get("status") in ("delivered", "accepted"):
            for item in order.get("items", []):
                pid = item.get("product_id")
                item_price = float(item.get("price_at_purchase", 0))
                qty = item.get("quantity", 1)
                
                prod = product_map.get(pid, {})
                cat = prod.get("category", "Uncategorized")
                category_revenue[cat] += (item_price * qty)

    categories_pie = [
        {"name": cat, "value": round(rev, 2)}
        for cat, rev in sorted(category_revenue.items(), key=lambda x: x[1], reverse=True)[:5]
    ]

    # Bazaar rankings
    bazaar_map = {b["id"]: b for b in bazaars}
    sorted_bazaars = sorted(bazaar_revenue.items(), key=lambda x: x[1], reverse=True)

    bazaar_rankings = []
    for i, (bid, rev) in enumerate(sorted_bazaars):
        bazaar = bazaar_map.get(bid, {})
        tier = "gold" if i < 3 else "silver" if i < 10 else "bronze"
        bazaar_rankings.append({
            "id": bid,
            "name": bazaar.get("nameAr", "بازار بدون اسم"),
            "revenue": round(rev, 2),
            "orders": bazaar_orders_count[bid],
            "tier": tier,
            "rank": i + 1,
        })

    if not bazaar_rankings:
        bazaar_rankings.append({
            "id": "none", "name": "لا مبيعات", "revenue": 0.0,
            "orders": 0, "tier": "bronze", "rank": 1,
        })

    return {
        "period": period,
        "key_metrics": {
            "total_revenue": round(total_revenue, 2),
            "total_orders": len(orders),
            "delivered_orders": status_counts.get("delivered", 0),
            "total_customers": user_count,
            "total_bazaars": len(bazaars),
            "active_bazaars": len(bazaar_revenue),
            "total_products": len(products),
            "cancellation_rate": round((status_counts.get("cancelled", 0) / len(orders) * 100), 2) if orders else 0.0,
        },
        "bazaar_rankings": bazaar_rankings[:10],
        "inactive_bazaars": [
            b for b in bazaars
            if b["id"] not in bazaar_revenue and b.get("isApproved")
        ],
        "status_distribution": dict(status_counts),
        "charts_data": {
            "revenue_line": [
                {"date": d, "revenue": daily_revenue[d]}
                for d in sorted(daily_revenue.keys())
            ],
            "categories_pie": categories_pie,
            "bazaar_bar": bazaar_rankings[:5],
        },
    }


async def get_platform_health() -> dict:
    """Get platform health metrics."""
    products = await get_all_products()
    bazaars = await get_all_bazaars()

    approved_bazaars = [b for b in bazaars if b.get("isApproved", True)]

    return {
        "health_score": 100,
        "bazaars": {"total": len(bazaars), "approved": len(approved_bazaars)},
        "products": {
            "total": len(products),
            "active": len([p for p in products if p.get("isActive", True)]),
            "no_image": 0,
            "no_description": 0,
        },
    }
