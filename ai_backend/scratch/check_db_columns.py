import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

AURORA_HOST = os.getenv("AURORA_HOST")
AURORA_USER = os.getenv("AURORA_USER")
AURORA_PASS = os.getenv("AURORA_PASS")
AURORA_DB = os.getenv("AURORA_DB")

def check_columns():
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
            cur.execute("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = 'products'
                ORDER BY ordinal_position;
            """)
            cols = cur.fetchall()
            print("Columns in 'products' table:")
            for col in cols:
                print(f" - {col[0]}: {col[1]}")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_columns()
