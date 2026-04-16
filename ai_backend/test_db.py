import asyncio
from services.aws_db_service import _execute_aurora_query
from psycopg2.extras import RealDictCursor

def run():
    def _query(conn):
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT o.status, COUNT(o.id) FROM orders o GROUP BY o.status")
            print("Orders Statuses:", cur.fetchall())
            
            cur.execute("SELECT COUNT(*) FROM order_items")
            print("Order Items Count:", cur.fetchall())

            cur.execute("""
                SELECT 
                    oi.product_name,
                    oi.product_id,
                    COUNT(oi.id) as order_count,
                    SUM(oi.total_price)::FLOAT as total_revenue
                FROM order_items oi
                JOIN orders o ON oi.order_id = o.id
                GROUP BY oi.product_name, oi.product_id
            """)
            print("JOIN result:", cur.fetchall()[:5])

    _execute_aurora_query(_query)

run()
