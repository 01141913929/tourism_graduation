# ============================================================
# Outputs — Displayed after terraform apply
# ============================================================

output "websocket_api_url" {
  value       = "wss://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
  description = "The WebSocket API endpoint for the AI backend"
}

output "lambda_function_name" {
  value       = aws_lambda_function.ai_planner.function_name
  description = "The name of the deployed Lambda function"
}

output "aurora_endpoint" {
  value       = aws_rds_cluster.aurora_v2.endpoint
  description = "Aurora Serverless V2 cluster endpoint"
  sensitive   = true
}

output "admin_api_url" {
  value       = aws_apigatewayv2_stage.admin_prod_stage.invoke_url
  description = "The HTTP API URL for the Admin AI Microservice"
}

output "tourist_http_api_url" {
  value       = aws_apigatewayv2_stage.tourist_http_stage.invoke_url
  description = "The HTTP API URL for the Tourist AI Microservice"
}
