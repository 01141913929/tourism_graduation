import firebase_admin
from firebase_admin import credentials, firestore
import json
import sys

# Set stdout to UTF-8
sys.stdout.reconfigure(encoding='utf-8')

cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def dump_sample(coll_id):
    docs = list(db.collection(coll_id).limit(1).get())
    if docs:
        print(f"--- {coll_id} ---")
        print(json.dumps(docs[0].to_dict(), ensure_ascii=False, indent=2))
    else:
        print(f"--- {coll_id} (EMPTY) ---")

dump_sample('messages')
dump_sample('visitor_stories')
dump_sample('orders')
dump_sample('app_settings')
