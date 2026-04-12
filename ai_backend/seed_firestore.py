"""
🌱 Firestore Seeder — ملء قاعدة البيانات ببيانات مصرية واقعية
نفّذ بـ: python seed_firestore.py
"""
import firebase_admin
from firebase_admin import credentials, firestore
from seed_data import BAZAARS, PRODUCTS

def seed():
    # اتصال بـ Firebase
    if not firebase_admin._apps:
        cred = credentials.Certificate("service_account.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    # رفع البازارات
    print("🏪 جاري رفع البازارات...")
    for b in BAZAARS:
        db.collection("bazaars").document(b["id"]).set(b)
        print(f"  ✅ {b['nameAr']}")

    # رفع المنتجات
    print("\n📦 جاري رفع المنتجات...")
    for p in PRODUCTS:
        db.collection("products").document(p["id"]).set(p)
        print(f"  ✅ {p['nameAr']} — {p['category']}")

    print(f"\n🎉 تم رفع {len(BAZAARS)} بازار و {len(PRODUCTS)} منتج بنجاح!")

if __name__ == "__main__":
    seed()
