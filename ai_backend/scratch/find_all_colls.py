import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

found_collections = set()

def scan_collections(ref, depth=0):
    if depth > 2: return # Don't go too deep
    colls = ref.collections()
    for coll in colls:
        found_collections.add(coll.id)
        # Check first doc for subcollections
        docs = list(coll.limit(1).stream())
        if docs:
            scan_collections(docs[0].reference, depth + 1)

print("Scanning for all collection IDs...")
scan_collections(db)
print(f"Found collections: {sorted(list(found_collections))}")
