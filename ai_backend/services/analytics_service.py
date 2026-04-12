"""
📊 Analytics Service — تحليلات متقدمة وسريعة باستخدام Aurora PostgreSQL (AWS Native)
"""
import asyncio
from datetime import datetime, timedelta
from collections import defaultdict
from services.aws_db_service import (
    get_all_products, get_bazaar_by_id, get_all_bazaars,
    get_bazaar_orders, get_bazaar_reviews, get_bazaar_messages, get_all_orders
)


# ============================================================
# Bazaar-Level Analytics (Owner App)
# ============================================================

async def compute_bazaar_analytics(bazaar_id: str, period: str = "week") -> dict:
    """حساب تحليلات شاملة للمالك بناءً على قواعد بيانات AWS Aurora."""
    days_map = {"day": 1, "week": 7, "month": 30, "quarter": 90, "year": 365}
    days = days_map.get(period, 7)

    # Fetch data concurrently
    all_products, orders, reviews = await asyncio.gather(
        get_all_products(),
        get_bazaar_orders(bazaar_id, days),
        get_bazaar_reviews(bazaar_id),
    )

    bazaar_products = [p for p in all_products if p.get("bazaarId") == bazaar_id]

    total_revenue = 0.0
    daily_revenue = defaultdict(float)
    daily_orders = defaultdict(int)
    product_sales = defaultdict(lambda: {"quantity": 0, "revenue": 0.0, "name": ""})
    status_counts = defaultdict(int)

    for order in orders:
        subtotal = float(order.get("subtotal", 0) or 0)
        status = order.get("status", "unknown")
        status_counts[status] += 1

        if status in ("delivered", "accepted", "preparing"):
            total_revenue += subtotal

        created_at = order.get("created_at")
        if created_at:
            if hasattr(created_at, "strftime"):
                day_key = created_at.strftime("%Y-%m-%d")
            else:
                day_key = str(created_at)[:10]
            daily_revenue[day_key] += subtotal
            daily_orders[day_key] += 1

        for item in order.get("items", []):
            pid = item.get("product_id", "")
            qty = int(item.get("quantity", 1))
            total_price = float(item.get("total_price", 0))
            product_sales[pid]["quantity"] += qty
            product_sales[pid]["revenue"] += total_price
            product_sales[pid]["name"] = item.get("product_name", "منتج")

    # Get Previous period for comparison
    prev_orders = await get_bazaar_orders(bazaar_id, days * 2)
    cutoff = datetime.utcnow() - timedelta(days=days)
    prev_revenue = 0.0
    for order in prev_orders:
        created_at = order.get("created_at")
        is_previous_period = False
        if hasattr(created_at, "replace"):
            # Ensure naive processing
            cnaive = created_at.replace(tzinfo=None)
            if cnaive < cutoff:
                is_previous_period = True
        elif isinstance(created_at, str) and created_at < cutoff.isoformat():
            is_previous_period = True

        if is_previous_period and order.get("status") in ("delivered", "accepted", "preparing"):
            prev_revenue += float(order.get("subtotal", 0) or 0)

    revenue_change = 0.0
    if prev_revenue > 0:
        revenue_change = ((total_revenue - prev_revenue) / prev_revenue) * 100

    # Sort daily data
    sorted_days = sorted(daily_revenue.keys())
    revenue_chart = [
        {"date": d, "revenue": round(daily_revenue[d], 2), "orders": daily_orders[d]}
        for d in sorted_days
    ]

    # Top products
    sorted_products = sorted(product_sales.items(), key=lambda x: x[1]["revenue"], reverse=True)[:10]
    top_products = [
        {"id": pid, "name": data["name"], "quantity": data["quantity"], "revenue": round(data["revenue"], 2)}
        for pid, data in sorted_products
    ]

    # Avg rating
    avg_rating = 0.0
    if reviews:
        ratings = [float(r.get("rating", 0)) for r in reviews if r.get("rating")]
        avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else 0.0

    return {
        "period": period,
        "days": days,
        "revenue": {
            "total": round(total_revenue, 2),
            "previous": round(prev_revenue, 2),
            "change_pct": round(revenue_change, 1),
            "trend": "up" if revenue_change > 0 else "down" if revenue_change < 0 else "flat",
        },
        "orders": {
            "total": len(orders),
            "delivered": status_counts.get("delivered", 0),
            "cancelled": status_counts.get("cancelled", 0),
            "pending": status_counts.get("pending", 0),
        },
        "products": {
            "total": len(bazaar_products),
            "active": len([p for p in bazaar_products if p.get("isActive", True)]),
            "no_description": len([p for p in bazaar_products if not p.get("descriptionAr")]),
        },
        "rating": {"average": avg_rating, "count": len(reviews)},
        "top_products": top_products,
        "peak_hours": [],
        "low_performers": [],
        "charts_data": {
            "revenue_line": revenue_chart,
            "categories_pie": [],
            "hourly_bar": [],
            "products_bar": top_products[:5],
        },
    }


# ============================================================
# Platform-Level Analytics (Admin Panel)
# ============================================================

async def compute_platform_analytics(period: str = "month") -> dict:
    """تحليلات شاملة للمنصة للمديرين (Admin AI)."""
    days_map = {"week": 7, "month": 30, "quarter": 90, "year": 365}
    days = days_map.get(period, 30)

    orders_task = get_all_orders(days)
    bazaars_task = get_all_bazaars()
    products_task = get_all_products()

    orders, bazaars, products = await asyncio.gather(
        orders_task, bazaars_task, products_task
    )

    total_revenue = 0.0
    daily_revenue = defaultdict(float)
    bazaar_revenue = defaultdict(float)
    bazaar_orders = defaultdict(int)
    status_counts = defaultdict(int)

    for order in orders:
        total = float(order.get("total", 0) or 0)
        status = order.get("status", "unknown")
        status_counts[status] += 1

        if status in ("delivered", "accepted"):
            total_revenue += total
            bid = order.get("bazaar_id", "unknown")
            bazaar_revenue[bid] += total
            bazaar_orders[bid] += 1

            created_at = order.get("created_at")
            if created_at:
                if hasattr(created_at, "strftime"):
                    day_key = created_at.strftime("%Y-%m-%d")
                else:
                    day_key = str(created_at)[:10]
                daily_revenue[day_key] += total

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
            "orders": bazaar_orders[bid],
            "tier": tier,
            "rank": i + 1,
        })

    if not bazaar_rankings:
        bazaar_rankings.append({"id": "dummy", "name": "لا مبيعات", "revenue": 0.0, "orders": 0, "tier": "bronze", "rank": 1})

    return {
        "period": period,
        "key_metrics": {
            "total_revenue": round(total_revenue, 2),
            "total_orders": len(orders),
            "delivered_orders": status_counts.get("delivered", 0),
            "total_customers": 0,
            "total_bazaars": len(bazaars),
            "active_bazaars": len(bazaar_revenue.keys()),
            "total_products": len(products),
            "cancellation_rate": 0.0,
        },
        "bazaar_rankings": bazaar_rankings[:10],
        "inactive_bazaars": [b for b in bazaars if b["id"] not in bazaar_revenue and b.get("isApproved")],
        "status_distribution": dict(status_counts),
        "charts_data": {
            "revenue_line": [{"date": d, "revenue": daily_revenue[d]} for d in sorted(daily_revenue.keys())],
            "categories_pie": [],
            "bazaar_bar": bazaar_rankings[:5],
        },
    }

async def get_platform_health() -> dict:
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

async def get_market_prices(category: str) -> dict:
    all_p = await get_all_products()
    prices = [float(p.get("price", 0)) for p in all_p if p.get("category") == category and p.get("price")]
    
    if not prices:
        return {"average": 0, "min": 0, "max": 0, "count": 0}

    return {
        "average": round(sum(prices) / len(prices), 2),
        "min": min(prices),
        "max": max(prices),
        "median": sorted(prices)[len(prices) // 2],
        "count": len(prices),
    }
