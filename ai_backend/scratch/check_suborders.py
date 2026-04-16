import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()
suborders = db.collection('subOrders').limit(1).stream()
for doc in suborders:
    print(f"SubOrder: {doc.id}")
    print(f"Keys: {doc.to_dict().keys()}")
    print(f"Data: {doc.to_dict()}")
