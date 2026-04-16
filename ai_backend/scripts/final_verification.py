import asyncio
import json
import os
from core.analytics_service import compute_platform_analytics
from core.db_service import get_all_products

async def test_logic():
    results = {}
    
    # 1. Products Check
    products = await get_all_products()
    if products:
        p = products[0]
        required_fields = ["descriptionAr", "imageUrl", "price", "category"]
        missing = [f for f in required_fields if f not in p or p[f] is None]
        results["products"] = {
            "count": len(products),
            "sample_fields": list(p.keys()),
            "has_full_data": len(missing) == 0,
            "missing_fields": missing
        }
    else:
        results["products"] = "No products found"

    # 2. Analytics Check
    analytics = await compute_platform_analytics("month")
    if analytics and "key_metrics" in analytics:
        results["analytics"] = {
            "status": "success",
            "revenue": analytics['key_metrics'].get('total_revenue'),
            "orders": analytics['key_metrics'].get('total_orders')
        }
    else:
        results["analytics"] = "Failed"

    # 3. Categories/Halls Check
    from core.db_service import get_all_categories, get_all_halls
    cats = await get_all_categories()
    halls = await get_all_halls()
    results["additional_tables"] = {
        "categories_count": len(cats),
        "halls_count": len(halls)
    }

    with open("scratch/final_verification.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("Verification saved to scratch/final_verification.json")

if __name__ == "__main__":
    asyncio.run(test_logic())
