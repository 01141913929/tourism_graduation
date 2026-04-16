import boto3
import os
from dotenv import load_dotenv

load_dotenv()

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)

tables = [
    "AiCarts",
    "AiConnections",
    "AiCoupons",
    "AiEpisodes",
    "AiSessions",
    "UserPreferences"
]

print("--- DynamoDB Table Status ---")
for table_name in tables:
    try:
        table = dynamodb.Table(table_name)
        count = table.item_count
        # item_count can be stale, so let's do a scan for small tables
        if count == 0:
             res = table.scan(Select='COUNT')
             count = res.get('Count', 0)
        print(f"Table: {table_name:20} | Item Count: {count}")
    except Exception as e:
        print(f"Table: {table_name:20} | Error: {e}")
