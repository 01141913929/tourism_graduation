import os
import psycopg2
from dotenv import load_dotenv
import json

load_dotenv()

AURORA_HOST = os.getenv("AURORA_HOST")
AURORA_USER = os.getenv("AURORA_USER")
AURORA_PASS = os.getenv("AURORA_PASS")
AURORA_DB = os.getenv("AURORA_DB")

def sample_data():
    try:
        conn = psycopg2.connect(
            host=AURORA_HOST,
            database=AURORA_DB,
            user=AURORA_USER,
            password=AURORA_PASS,
            sslmode='require',
            connect_timeout=10
        )
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM products LIMIT 3;")
            rows = cur.fetchall()
            colnames = [desc[0] for desc in cur.description]
            
            results = []
            for row in rows:
                results.append(dict(zip(colnames, row)))
            
            print(json.dumps(results, indent=2, default=str, ensure_ascii=False))
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    sample_data()
