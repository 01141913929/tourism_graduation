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
    """تحليلات شاملة للمنصة للمديرين (Admin AI) — محسنة باستخدام SQL."""
    days_map = {"week": 7, "month": 30, "quarter": 90, "year": 365}
    days = days_map.get(period, 30)

    from services.aws_db_service import (
        get_platform_metrics_sql, get_bazaar_rankings_sql,
        get_category_distribution_sql, get_revenue_trend_sql
    )

    # Fetch optimized metrics concurrently
    metrics, rankings, categories, revenue_trend = await asyncio.gather(
        get_platform_metrics_sql(days),
        get_bazaar_rankings_sql(days, limit=10),
        get_category_distribution_sql(),
        get_revenue_trend_sql(days),
    )

    # Format rankings for the UI
    bazaar_rankings = []
    for i, r in enumerate(rankings):
        bazaar_rankings.append({
            "id": r["id"],
            "name": r["name"],
            "revenue": float(r["revenue"]),
            "orders": r["order_count"],
            "tier": "gold" if i < 3 else "silver" if i < 6 else "bronze",
            "rank": i + 1,
        })

    if not bazaar_rankings:
        bazaar_rankings.append({"id": "dummy", "name": "لا مبيعات خالية", "revenue": 0.0, "orders": 0, "tier": "bronze", "rank": 1})

    return {
        "period": period,
        "key_metrics": {
            "total_revenue": float(metrics["total_revenue"]),
            "total_orders": metrics["total_orders"],
            "delivered_orders": metrics["delivered_orders"],
            "total_customers": metrics.get("total_customers", 0),
            "total_bazaars": metrics["total_bazaars"],
            "active_bazaars": metrics["active_bazaars"],
            "total_products": metrics["total_products"],
            "cancellation_rate": metrics["cancellation_rate"],
        },
        "bazaar_rankings": bazaar_rankings,
        "inactive_bazaars": [], 
        "status_distribution": {}, 
        "charts_data": {
            "revenue_line": revenue_trend,
            "categories_pie": [{"category": c["category"] or "عام", "revenue": c["count"]} for c in categories[:6]],
            "bazaar_bar": bazaar_rankings[:5],
        },
    }

async def get_platform_health() -> dict:
    """الحصول على صحة المنصة الحقيقية بناءً على جودة البيانات."""
    from services.aws_db_service import get_system_health_metrics_sql
    health = await get_system_health_metrics_sql()
    
    return {
        "health_score": health["health_score"],
        "bazaars": {"total": health.get("bazaars_total", 0), "approved": 0}, # Simplified
        "products": {
            "total": health["products_total"],
            "active": health["products_total"], # Placeholder
            "no_image": health["missing_images"],
            "no_description": health["missing_descriptions"],
        },
        "pending_applications": health["pending_applications"]
    }

async def get_market_prices(category: str) -> dict:
    """تحليل أسعار السوق لفئة معينة باستخدام SQL."""
    from services.aws_db_service import get_market_prices_sql
    stats = await get_market_prices_sql(category)
    
    if not stats or stats.get("count", 0) == 0:
        return {"average": 0, "min": 0, "max": 0, "count": 0, "median": 0}

    return {
        "average": round(stats["average"], 2),
        "min": stats["min"],
        "max": stats["max"],
        "median": stats["median"],
        "count": stats["count"],
    }
