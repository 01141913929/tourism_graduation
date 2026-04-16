import firebase_admin
from firebase_admin import credentials, firestore

def list_all_collections():
    cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    collections = db.collections()
    for coll in collections:
        docs = coll.limit(1).get()
        count = 0 # Firestore doesn't provide a cheap count, but we can sample
        print(f"Collection: {coll.id}")

if __name__ == "__main__":
    list_all_collections()
