"""
🚀 AWS Lambda Entry Point for Admin AI Service
Uses Mangum to wrap FastAPI for AWS REST API Gateway.
"""
from mangum import Mangum
from services.admin.app import app
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

mangum_handler = Mangum(app, lifespan="off")

def lambda_handler(event, context):
    print(f"Received event: {event}")
    return mangum_handler(event, context)
