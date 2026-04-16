import firebase_admin
from firebase_admin import credentials, firestore
import json

def sample_docs():
    cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    samples = {}
    collections = ['bazaars', 'products', 'users', 'carts', 'chats']
    for coll in collections:
        docs = db.collection(coll).limit(1).get()
        if docs:
            samples[coll] = docs[0].to_dict()
        else:
            samples[coll] = "Table Empty"
            
    print(json.dumps(samples, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    sample_docs()
