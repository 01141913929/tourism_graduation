import firebase_admin
from firebase_admin import credentials, firestore
import json

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def sample_collection(coll_id, limit=3):
    print(f"\n--- {coll_id} ---")
    docs = list(db.collection(coll_id).limit(limit).stream())
    for doc in docs:
        print(f"ID: {doc.id}")
        data = doc.to_dict()
        # Find subcollections
        subcolls = list(doc.reference.collections())
        if subcolls:
            print(f"  Subcollections: {[s.id for s in subcolls]}")
        # Print a snippet of data
        print(f"  Data keys: {list(data.keys())}")

# Search for coupons and episodes in root collections
sample_collection('messages')
sample_collection('visitor_stories')
sample_collection('artifacts')
sample_collection('bazaars')
sample_collection('users')

print("\n--- Deep Scan for Coupons/Episodes ---")
# Check subcollections of first bazaar and first user
bazaars = list(db.collection('bazaars').limit(5).stream())
for b in bazaars:
    sc = list(b.reference.collections())
    if sc:
        print(f"Bazaar {b.id} has subcolls: {[s.id for s in sc]}")

users = list(db.collection('users').limit(5).stream())
for u in users:
    sc = list(u.reference.collections())
    if sc:
        print(f"User {u.id} has subcolls: {[s.id for s in sc]}")
