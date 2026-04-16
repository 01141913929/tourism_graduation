import firebase_admin
from firebase_admin import credentials, firestore

keys = [
    "c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json",
    "c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-609883dfd3.json"
]

for i, key in enumerate(keys):
    print(f"\n=== Checking Key {i+1}: {key} ===")
    try:
        # Check if already initialized, if so, delete app
        if firebase_admin._apps:
            for app_name in list(firebase_admin._apps.keys()):
                firebase_admin.delete_app(firebase_admin._apps[app_name])
        
        cred = credentials.Certificate(key)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        
        collections = db.collections()
        for coll in collections:
             # Just check if it has documents
             docs = list(db.collection(coll.id).limit(5).stream())
             print(f"Collection: {coll.id:20} | Top Docs: {len(docs)}")
             if docs:
                 print(f"  Sample Keys: {list(docs[0].to_dict().keys())}")
                 
    except Exception as e:
        print(f"Error checking key {i+1}: {e}")
