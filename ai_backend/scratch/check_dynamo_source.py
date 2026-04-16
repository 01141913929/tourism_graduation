import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Check Carts
print("\n--- CARTS SAMPLE ---")
carts = db.collection('carts').limit(1).stream()
for doc in carts:
    print(f"Cart ID: {doc.id}")
    print(f"Data: {doc.to_dict()}")

# Check Chats/Sessions
print("\n--- CHATS SAMPLE ---")
chats = db.collection('chats').limit(1).stream()
for doc in chats:
    print(f"Chat ID: {doc.id}")
    print(f"Data: {doc.to_dict()}")

# Check User preferences (often inside user doc)
print("\n--- USER PREFS SAMPLE ---")
users = db.collection('users').limit(1).stream()
for doc in users:
    data = doc.to_dict()
    print(f"User: {doc.id}")
    print(f"Keys: {list(data.keys())}")
    # Look for preferences/favorites
    if 'favorites' in data or 'preferences' in data:
       print(f"Found: { {k: data[k] for k in ['favorites', 'preferences'] if k in data} }")
