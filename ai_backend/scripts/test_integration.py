import requests
import json

def test_admin_api():
    base_url = "http://127.0.0.1:8000/api/admin/ai" # Assuming local dev for testing
    
    print("Testing GET /platform-insights ...")
    try:
        r = requests.get(f"{base_url}/platform-insights")
        if r.status_code == 200:
            print("✅ Success!")
            # print(json.dumps(r.json(), indent=2, ensure_ascii=False))
        else:
            print(f"❌ Failed: {r.status_code}")
    except Exception as e:
        print(f"Connection error: {e}")

    print("\nVerifying Product Details in compute_platform_analytics ...")
    # We can't hit the internal functions directly via requests easily if they aren't endpoints,
    # but we can check the Business Report which uses them.
    
    print("Testing POST /business-report ...")
    try:
        r = requests.post(f"{base_url}/business-report", json={"period": "month", "focus": "products"})
        if r.status_code == 200:
            print("✅ Success!")
            data = r.json()
            if "key_metrics" in data:
                print(f"Metrics: {data['key_metrics']}")
        else:
            print(f"❌ Failed: {r.status_code}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_admin_api()
