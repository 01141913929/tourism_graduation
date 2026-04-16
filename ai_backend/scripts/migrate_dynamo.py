import os
import sys
import json
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Add the parent directory to sys.path to import core modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.aws_memory import get_dynamo_table, DYNAMODB_PREFS_TABLE, DYNAMODB_SESSIONS_TABLE

def migrate_user_preferences(db):
    print("Migrating User Preferences to DynamoDB...")
    table = get_dynamo_table(DYNAMODB_PREFS_TABLE)
    users_ref = db.collection('users').stream()
    count = 0
    for doc in users_ref:
        data = doc.to_dict()
        user_id = doc.id
        
        # Extract relevant preference data
        prefs = {
            "favorite_products": data.get("favoriteProductIds", []),
            "favorite_artifacts": data.get("favoriteArtifactIds", []),
            "addresses": data.get("addresses", []),
            "role": data.get("role", "USER"),
            "name": data.get("name", "Unknown User")
        }
        
        try:
            table.put_item(Item={
                'UserId': user_id,
                'Preferences': json.dumps(prefs, ensure_ascii=False),
                'MigratedAt': datetime.utcnow().isoformat()
            })
            count += 1
        except Exception as e:
            print(f"Error migrating user {user_id}: {e}")
            
    print(f"Successfully migrated {count} user preference profiles.")

def migrate_chats_to_sessions(db):
    print("Migrating Chat History to DynamoDB Sessions...")
    table = get_dynamo_table(DYNAMODB_SESSIONS_TABLE)
    chats_ref = db.collection('chats').stream()
    count = 0
    for doc in chats_ref:
        data = doc.to_dict()
        session_id = doc.id
        
        # In Dynamo, AiSessions uses SessionId (H)
        try:
            table.put_item(Item={
                'SessionId': session_id,
                'Data': json.dumps(data, ensure_ascii=False),
                'UpdatedAt': datetime.utcnow().isoformat()
            })
            count += 1
        except Exception as e:
            print(f"Error migrating chat {session_id}: {e}")
    print(f"Successfully migrated {count} chat sessions.")

def run_migration():
    cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    migrate_user_preferences(db)
    migrate_chats_to_sessions(db)
    
    # Check for carts
    print("Checking for carts...")
    carts_ref = db.collection('carts').stream()
    cart_table = get_dynamo_table("AiCarts")
    ccount = 0
    for doc in carts_ref:
        data = doc.to_dict()
        try:
            cart_table.put_item(Item={
                'UserId': doc.id,
                'Items': json.dumps(data.get("items", []), ensure_ascii=False),
                'UpdatedAt': datetime.utcnow().isoformat()
            })
            ccount += 1
        except Exception as e:
            print(f"Error migrating cart {doc.id}: {e}")
    print(f"Successfully migrated {ccount} shopping carts.")

if __name__ == "__main__":
    run_migration()
