import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()
# Check for order sub-collections
orders = db.collection('orders').limit(1).stream()
for doc in orders:
    print(f"Order: {doc.id}")
    collections = doc.reference.collections()
    for col in collections:
        print(f"  Sub-collection: {col.id}")

# Check for other likely collections
all_collections = db.collections()
print("\nAll Root Collections:")
for col in all_collections:
    print(f" - {col.id}")
