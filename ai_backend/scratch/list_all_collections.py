import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# List all root collections
collections = db.collections()
for coll in collections:
    docs = db.collection(coll.id).limit(1).get()
    print(f"Collection: {coll.id} | Count (at least 1): {len(docs)}")
    if docs:
        print(f"  Field keys: {list(docs[0].to_dict().keys())}")
