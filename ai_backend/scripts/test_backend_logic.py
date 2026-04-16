import asyncio
import json
from core.analytics_service import compute_platform_analytics
from core.db_service import get_all_products

async def test_logic():
    print("Testing get_all_products()...")
    products = await get_all_products()
    if products:
        print(f"✅ Found {len(products)} products.")
        # Check first product for full fields
        p = products[0]
        required_fields = ["descriptionAr", "imageUrl", "price", "category"]
        missing = [f for f in required_fields if f not in p or p[f] is None]
        if not missing:
            print("✅ All fields present (Description, Image, Price, Category).")
            # print(json.dumps(p, indent=2, ensure_ascii=False))
        else:
            print(f"❌ Missing fields: {missing}")
            print(f"First product keys: {list(p.keys())}")
    else:
        print("❌ No products found.")

    print("\nTesting compute_platform_analytics()...")
    analytics = await compute_platform_analytics("month")
    if analytics and "key_metrics" in analytics:
        print("✅ Analytics computed successfully.")
        print(f"Total Revenue: {analytics['key_metrics'].get('total_revenue')}")
        print(f"Total Orders: {analytics['key_metrics'].get('total_orders')}")
    else:
        print("❌ Analytics failed.")

if __name__ == "__main__":
    asyncio.run(test_logic())
