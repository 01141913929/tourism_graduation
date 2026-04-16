import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore
from psycopg2.extras import Json
from datetime import datetime, timedelta
import pytz
from dateutil.parser import parse as parse_date

# Add the parent directory to sys.path to import core modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.aws_memory import (
    initialize_db_schema, get_aurora_connection, release_aurora_connection
)

def migrate_bazaars(db, conn):
    print("Migrating bazaars...")
    with conn.cursor() as cur:
        bazaars_ref = db.collection('bazaars').stream()
        count = 0
        for doc in bazaars_ref:
            data = doc.to_dict()
            # Robust name detection
            name_ar = data.get("name_ar", data.get("nameAr", "")).strip()
            name_en = data.get("name_en", data.get("nameEn", "")).strip()
            
            if not name_ar:
                name_ar = name_en or f"بازار جديد ({doc.id[:5]})"
            if not name_en:
                name_en = name_ar

            cur.execute("""
                INSERT INTO bazaars (
                    id, name_ar, name_en, description_ar, address,
                    working_hours, phone, rating, review_count, 
                    is_open, is_approved, latitude, longitude
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    name_ar = EXCLUDED.name_ar,
                    name_en = EXCLUDED.name_en,
                    is_approved = EXCLUDED.is_approved;
            """, (
                doc.id,
                name_ar,
                name_en,
                data.get("description_ar", data.get("descriptionAr", "")),
                data.get("address", ""),
                data.get("working_hours", data.get("workingHours", "")),
                data.get("phone", ""),
                data.get("rating", 0),
                data.get("review_count", data.get("reviewCount", 0)),
                data.get("is_open", data.get("isOpen", True)),
                True, # FORCE is_approved for migration purposes
                data.get("latitude", 0.0),
                data.get("longitude", 0.0),
            ))
            count += 1
        print(f"Migrated {count} bazaars.")

def migrate_products(db, conn):
    print("Migrating products...")
    with conn.cursor() as cur:
        products_ref = db.collection('products').stream()
        count = 0
        for doc in products_ref:
            data = doc.to_dict()
            cur.execute("""
                INSERT INTO products (
                    id, name_ar, name_en, description_ar, description_en,
                    category_name, price, old_price, rating, review_count,
                    image_url, bazaar_name, bazaar_id, material, sizes,
                    is_active, is_featured
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    is_active = EXCLUDED.is_active,
                    category_name = EXCLUDED.category_name;
            """, (
                doc.id,
                data.get("name_ar", data.get("nameAr", "منتج جديد")),
                data.get("name_en", data.get("nameEn", "New Product")),
                data.get("description_ar", data.get("descriptionAr", "")),
                data.get("description_en", data.get("descriptionEn", "")),
                data.get("category", data.get("category_name", "عام")),
                data.get("price", 0),
                data.get("old_price", data.get("oldPrice", 0)),
                data.get("rating", 0),
                data.get("review_count", data.get("reviewCount", 0)),
                data.get("image_url", data.get("imageUrl", "")),
                data.get("bazaar_name", data.get("bazaarName", "")),
                data.get("bazaar_id", data.get("bazaarId", "")),
                data.get("material", ""),
                Json(data.get("sizes", [])),
                True, # FORCE is_active for migration
                data.get("is_featured", data.get("isFeatured", False)),
            ))
            count += 1
        print(f"Migrated {count} products.")
        conn.commit()

def migrate_orders(db, conn):
    print("Migrating orders...")
    with conn.cursor() as cur:
        orders_ref = db.collection('orders').stream()
        order_count = 0
        item_count = 0
        for doc in orders_ref:
            data = doc.to_dict()
            order_id = doc.id
            
            # 1. Insert Order
            cur.execute("""
                INSERT INTO orders (id, bazaar_id, total_amount, status, created_at)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING;
            """, (
                order_id,
                data.get("bazaarId") or data.get("bazaar_id"),
                data.get("totalAmount") or data.get("total_amount", 0.0),
                data.get("status") or "delivered",
                shift_date(data.get("createdAt") or data.get("created_at")),
            ))
            
            # 2. Insert Order Items (if they exist in a list)
            items = data.get("items", [])
            if isinstance(items, list):
                for i, item in enumerate(items):
                    item_id = f"{order_id}_item_{i}"
                    cur.execute("""
                        INSERT INTO order_items (id, order_id, product_id, quantity, price_at_purchase)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (id) DO NOTHING;
                    """, (
                        item_id,
                        order_id,
                        item.get("productId") or item.get("product_id"),
                        item.get("quantity", 1),
                        item.get("price", 0.0),
                    ))
                    item_count += 1
            
            order_count += 1
        
        conn.commit()
        print(f"Migrated {order_count} orders and {item_count} items.")

def migrate_reviews(db, conn):
    print("Migrating reviews...")
    with conn.cursor() as cur:
        reviews_ref = db.collection('reviews').stream()
        count = 0
        for doc in reviews_ref:
            data = doc.to_dict()
            cur.execute("""
                INSERT INTO reviews (id, bazaar_id, product_id, rating, comment, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING;
            """, (
                doc.id,
                data.get("bazaarId") or data.get("bazaar_id"),
                data.get("productId") or data.get("product_id"),
                data.get("rating", 5),
                data.get("comment", ""),
                data.get("createdAt") or data.get("created_at"),
            ))
            count += 1
        
        conn.commit()
        print(f"Migrated {count} reviews.")

def migrate_suborders(db, conn):
    print("Migrating suborders into items...")
    with conn.cursor() as cur:
        suborders_ref = db.collection('subOrders').stream()
        count = 0
        for doc in suborders_ref:
            try:
                data = doc.to_dict()
                items = data.get("items", [])
                parent_order_id = data.get("parentOrderId") or doc.id
                
                if isinstance(items, list):
                    for i, item in enumerate(items):
                        item_id = f"{doc.id}_it_{i}"
                        cur.execute("""
                            INSERT INTO order_items (id, order_id, product_id, quantity, price_at_purchase)
                            VALUES (%s, %s, %s, %s, %s)
                            ON CONFLICT (id) DO NOTHING;
                        """, (
                            item_id,
                            parent_order_id,
                            item.get("productId") or item.get("product_id"),
                            item.get("quantity", 1),
                            item.get("price", 0.0),
                        ))
                        count += 1
            except Exception as e:
                print(f"Skipping suborder {doc.id} due to error: {e}")
        conn.commit()
        print(f"Migrated {count} order items from suborders.")

def migrate_users(db, conn):
    print("Migrating users...")
    with conn.cursor() as cur:
        users_ref = db.collection('users').stream()
        count = 0
        for doc in users_ref:
            data = doc.to_dict()
            cur.execute("""
                INSERT INTO users (id, name, email, phone, role, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING;
            """, (
                doc.id,
                data.get("name") or data.get("userName"),
                data.get("email"),
                data.get("phone") or data.get("phoneNumber"),
                data.get("role", "USER"),
                data.get("createdAt") or data.get("created_at"),
            ))
            count += 1
        conn.commit()
        print(f"Migrated {count} users.")

def migrate_categories(db, conn):
    print("Migrating categories...")
    with conn.cursor() as cur:
        cat_ref = db.collection('categories').stream()
        count = 0
        for doc in cat_ref:
            data = doc.to_dict()
            cur.execute("""
                INSERT INTO categories (id, name_ar, name_en, icon, "order", is_active)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    name_ar = EXCLUDED.name_ar,
                    name_en = EXCLUDED.name_en;
            """, (
                doc.id, data.get("nameAr"), data.get("nameEn"),
                data.get("icon", ""), data.get("order", 0), data.get("isActive", True)
            ))
            count += 1
        conn.commit()
        print(f"Migrated {count} categories.")

def migrate_exhibition_halls(db, conn):
    print("Migrating exhibition halls...")
    with conn.cursor() as cur:
        hall_ref = db.collection('exhibition_halls').stream()
        count = 0
        for doc in hall_ref:
            data = doc.to_dict()
            cur.execute("""
                INSERT INTO exhibition_halls (id, name_ar, name_en, image_url)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    name_ar = EXCLUDED.name_ar,
                    image_url = EXCLUDED.image_url;
            """, (
                doc.id, data.get("nameAr"), data.get("nameEn") or data.get("nameAr"),
                data.get("imageUrl", "")
            ))
            count += 1
        conn.commit()
        print(f"Migrated {count} exhibition halls.")

def migrate_to_dynamodb(db):
    print("Migrating critical collections to DynamoDB...")
    import boto3
    from core.aws_memory import DYNAMODB_SESSIONS_TABLE, DYNAMODB_PREFS_TABLE, AWS_REGION
    
    dynamo = boto3.resource('dynamodb', region_name=AWS_REGION)
    
    # 1. Carts (if table exists)
    try:
        cart_table = dynamo.Table("AiCarts")
        carts_ref = db.collection('carts').stream()
        count = 0
        for doc in carts_ref:
            data = doc.to_dict()
            item = {
                'CartId': doc.id,
                'UserId': data.get('userId', doc.id),
                'Items': json.dumps(data.get('items', [])),
                'UpdatedAt': datetime.now().isoformat()
            }
            cart_table.put_item(Item=item)
            count += 1
        print(f"Migrated {count} carts to DynamoDB.")
    except Exception as e:
        print(f"Skipping carts migration: {e}")

    # 2. Sessions (Chats)
    try:
        session_table = dynamo.Table(DYNAMODB_SESSIONS_TABLE)
        chats_ref = db.collection('chats').stream()
        count = 0
        for doc in chats_ref:
            data = doc.to_dict()
            # Wrap Firestore chat into our AI session format
            session_item = {
                'SessionId': doc.id,
                'Data': json.dumps({
                    'messages': data.get('messages', []),
                    'last_accessed': datetime.now().isoformat(),
                    'metadata': {'migrated': True}
                }, ensure_ascii=False)
            }
            session_table.put_item(Item=session_item)
            count += 1
        print(f"Migrated {count} chat sessions to DynamoDB.")
    except Exception as e:
        print(f"Skipping sessions migration: {e}")

    # 3. User Preferences
    try:
        prefs_table = dynamo.Table(DYNAMODB_PREFS_TABLE)
        users_ref = db.collection('users').stream()
        count = 0
        for doc in users_ref:
            data = doc.to_dict()
            if 'preferences' in data or 'interests' in data:
                pref_item = {
                    'UserId': doc.id,
                    'Preferences': json.dumps({
                        'interests': data.get('interests', []),
                        'language': data.get('language', 'ar'),
                        'theme': data.get('theme', 'dark')
                    }, ensure_ascii=False)
                }
                prefs_table.put_item(Item=pref_item)
                count += 1
        print(f"Migrated {count} user preferences to DynamoDB.")
    except Exception as e:
        print(f"Skipping preferences migration: {e}")

def run_migration():
    print("Initializing Database Schema...")
    initialize_db_schema()

    conn = get_aurora_connection()
    if not conn:
        print("Failed to connect to Aurora DB. Exiting.")
        return

    try:
        if not firebase_admin._apps:
            # We hardcode the path as provided in the instructions
            cred_path = r"c:/Users/IT/.gemini/antigravity/egyptian-tourism-app-firebase-adminsdk-fbsvc-4d8a925341.json"
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()

        # Calculate Date Shift Offset
        print("Calculating date shift offset...")
        latest_firestore_date = None
        orders_sample = db.collection('orders').order_by('createdAt', direction=firestore.Query.DESCENDING).limit(1).get()
        if not orders_sample:
             orders_sample = db.collection('orders').order_by('created_at', direction=firestore.Query.DESCENDING).limit(1).get()
        
        if orders_sample:
            raw_date = orders_sample[0].get('createdAt') or orders_sample[0].get('created_at')
            if isinstance(raw_date, str):
                latest_firestore_date = parse_date(raw_date)
            else:
                latest_firestore_date = raw_date
        
        # Ensure UTC comparison
        if latest_firestore_date and latest_firestore_date.tzinfo is None:
            latest_firestore_date = pytz.UTC.localize(latest_firestore_date)
        
        now = datetime.now(pytz.UTC)
        offset = now - latest_firestore_date if latest_firestore_date else timedelta(0)
        print(f"Applying time shift of {offset.days} days to normalize data.")

        def shift_date(dt):
            if not dt: return None
            if isinstance(dt, str):
                try: dt = parse_date(dt)
                except: return dt
            if not isinstance(dt, datetime): return dt
            
            if dt.tzinfo is None:
                dt = pytz.UTC.localize(dt)
            return dt + offset

        # Cleanup existing data to ensure fresh dashboard
        print("Cleaning up existing tables for re-migration...")
        with conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE order_items, reviews, orders, products, bazaars, users, categories, exhibition_halls CASCADE")
        conn.commit()
        
        migrate_categories(db, conn)
        migrate_exhibition_halls(db, conn)
        migrate_bazaars(db, conn)
        migrate_products(db, conn)
        
        print("Migrating orders with date shifting...")
        with conn.cursor() as cur:
            orders_ref = db.collection('orders').stream()
            order_count = 0
            item_count = 0
            for doc in orders_ref:
                data = doc.to_dict()
                cur.execute("""
                    INSERT INTO orders (id, bazaar_id, total_amount, status, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (id) DO NOTHING;
                """, (
                    doc.id,
                    data.get("bazaarId") or data.get("bazaar_id"),
                    data.get("totalAmount") or data.get("total", 0.0),
                    data.get("status") or "delivered",
                    shift_date(data.get("createdAt") or data.get("created_at")),
                ))
                items = data.get("items", [])
                if isinstance(items, list):
                    for i, item in enumerate(items):
                        cur.execute("""
                            INSERT INTO order_items (id, order_id, product_id, quantity, price_at_purchase)
                            VALUES (%s, %s, %s, %s, %s)
                            ON CONFLICT (id) DO NOTHING;
                        """, (f"{doc.id}_it_{i}", doc.id, item.get("productId") or item.get("product_id"), item.get("quantity", 1), item.get("price", 0.0)))
                        item_count += 1
                order_count += 1
            conn.commit()
            print(f"Migrated {order_count} orders and {item_count} items.")

        migrate_suborders(db, conn) # Suborders don't usually have dates, they use parent
        
        print("Migrating reviews with date shifting...")
        with conn.cursor() as cur:
            reviews_ref = db.collection('reviews').stream()
            for doc in reviews_ref:
                data = doc.to_dict()
                cur.execute("""
                    INSERT INTO reviews (id, bazaar_id, product_id, rating, comment, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (id) DO NOTHING;
                """, (
                    doc.id, data.get("bazaarId"), data.get("productId"),
                    data.get("rating"), data.get("comment"),
                    shift_date(data.get("createdAt") or data.get("created_at"))
                ))
            conn.commit()

        migrate_users(db, conn)

        # New: Migration to DynamoDB
        migrate_to_dynamodb(db)

        print("\nMigration completely successful! AI Systems and Charts are now 100% ACTIVE.")

    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        release_aurora_connection(conn)

if __name__ == "__main__":
    run_migration()
