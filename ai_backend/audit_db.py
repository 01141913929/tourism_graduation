import os
import sys
import asyncio
from core.aws_memory import get_aurora_connection, release_aurora_connection

async def audit_data():
    conn = get_aurora_connection()
    if not conn:
        print("Failed to connect")
        return

    try:
        with conn.cursor() as cur:
            print("--- Bazaars Audit ---")
            cur.execute("SELECT COUNT(*) FROM bazaars;")
            print(f"Total Bazaars: {cur.fetchone()[0]}")
            cur.execute("SELECT id, name_ar, is_approved, is_open FROM bazaars LIMIT 5;")
            for row in cur.fetchall():
                print(row)

            print("\n--- Products Audit ---")
            cur.execute("SELECT COUNT(*) FROM products;")
            print(f"Total Products: {cur.fetchone()[0]}")
            cur.execute("SELECT id, name_ar, is_active FROM products LIMIT 5;")
            for row in cur.fetchall():
                print(row)

            print("\n--- Orders Audit ---")
            cur.execute("SELECT COUNT(*) FROM orders;")
            print(f"Total Orders: {cur.fetchone()[0]}")
            cur.execute("SELECT id, total_amount, created_at FROM orders LIMIT 5;")
            for row in cur.fetchall():
                print(row)

            print("\n--- Metrics Debug ---")
            # This is the query I used in get_platform_metrics_sql
            cur.execute("""
                SELECT 
                    (SELECT COUNT(*) FROM bazaars WHERE is_approved = true) as bazaars,
                    (SELECT COUNT(*) FROM products WHERE is_active = true) as products,
                    (SELECT COUNT(*) FROM orders WHERE created_at >= NOW() - INTERVAL '30 days') as orders
            """)
            print(f"Metrics (30 days): {cur.fetchone()}")

    finally:
        release_aurora_connection(conn)

if __name__ == "__main__":
    asyncio.run(audit_data())
