import os
import logging
import firebase_admin
from firebase_admin import credentials, firestore

logger = logging.getLogger(__name__)

_db = None

def get_firestore_client():
    global _db
    if _db is not None:
        return _db
    
    try:
        if not firebase_admin._apps:
            cred_path = os.environ.get("FIREBASE_CREDENTIALS", "secrets/firebase_credentials.json")
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin initialized using credentials file.")
            else:
                # Fallback, might work in AWS if role has access or if emulator is used
                firebase_admin.initialize_app()
                logger.info("Firebase Admin initialized with default credentials.")
        
        _db = firestore.client()
        return _db
    except Exception as e:
        logger.error(f"Failed to initialize Firestore client: {e}")
        return None
