import firebase_admin
from firebase_admin import credentials, firestore
import json

def check_missing_schemas():
    cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    results = {}
    for coll in ['categories', 'exhibition_halls']:
        docs = db.collection(coll).limit(1).get()
        if docs:
            results[coll] = docs[0].to_dict()
        else:
            results[coll] = "Empty"
            
    with open("scratch/missing_schemas.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("Saved to scratch/missing_schemas.json")

if __name__ == "__main__":
    check_missing_schemas()
