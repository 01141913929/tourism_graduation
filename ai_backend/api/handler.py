"""
AWS Lambda HTTP Handler (Mangum Proxy)
Exposes the main FastAPI application over AWS API Gateway HTTP APIs.
"""
from mangum import Mangum
from main import app
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

mangum_handler = Mangum(app, lifespan="auto", api_gateway_base_path="/deployment-test")

def lambda_handler(event, context):
    print(f"Received HTTP event route: {event.get('routeKey', 'unknown')}")
    return mangum_handler(event, context)
