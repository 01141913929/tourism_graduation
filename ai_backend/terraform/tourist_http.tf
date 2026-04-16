# ============================================================
# HTTP API Gateway for Tourist App (REST & SSE)
# ============================================================
resource "aws_apigatewayv2_api" "tourist_http_api" {
  name          = "${var.project_name}-tourist-http"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# The Lambda Function for Tourist REST Service
# Overrides the container CMD to point to our Mangum handler
resource "aws_lambda_function" "tourist_http_lambda" {
  function_name = "${var.project_name}-tourist-http-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.ai_backend_repo.repository_url}:latest"
  timeout       = 300
  memory_size   = 2048

  image_config {
    command = ["api.handler.lambda_handler"]
  }

  environment {
    variables = {
      # --- AWS Infra ---
      WS_CONNECTIONS_TABLE = aws_dynamodb_table.ws_connections.name
      SESSIONS_TABLE       = aws_dynamodb_table.ai_sessions.name
      PREFERENCES_TABLE    = aws_dynamodb_table.user_preferences.name

      # --- Aurora ---
      AURORA_HOST = aws_rds_cluster.aurora_v2.endpoint
      AURORA_USER = aws_rds_cluster.aurora_v2.master_username
      AURORA_PASS = aws_rds_cluster.aurora_v2.master_password
      AURORA_DB   = aws_rds_cluster.aurora_v2.database_name

      # --- API Keys ---
      LLM_PROVIDER         = "groq"
      GROQ_API_KEY          = var.groq_api_key
      GEMINI_API_KEY        = var.gemini_api_key
      GROQ_MODEL            = "openai/gpt-oss-120b"
      GROQ_FAST_MODEL       = "openai/gpt-oss-20b"
      GEMINI_MODEL          = "gemini-2.0-flash"
      GEMINI_EMBEDDING_MODEL = "models/gemini-embedding-001"

      # --- Langfuse Observability ---
      LANGFUSE_SECRET_KEY = "sk-lf-71e04a77-f388-45de-8cb3-7941132e6a77"
      LANGFUSE_PUBLIC_KEY = "pk-lf-ee2c3ee3-d115-49de-bab1-9d6264d289e0"
      LANGFUSE_BASE_URL   = "https://cloud.langfuse.com"

      # --- Operational ---
      LOG_LEVEL = "INFO"
      DEBUG     = "false"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy.lambda_dynamodb,
  ]
}

# API Gateway integration
resource "aws_apigatewayv2_integration" "tourist_http_integration" {
  api_id             = aws_apigatewayv2_api.tourist_http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.tourist_http_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "tourist_default_route" {
  api_id    = aws_apigatewayv2_api.tourist_http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.tourist_http_integration.id}"
}

# Root path route — handles /health and / requests
resource "aws_apigatewayv2_route" "tourist_root_route" {
  api_id    = aws_apigatewayv2_api.tourist_http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.tourist_http_integration.id}"
}

resource "aws_apigatewayv2_stage" "tourist_http_stage" {
  api_id      = aws_apigatewayv2_api.tourist_http_api.id
  name        = var.environment
  auto_deploy = true
}

resource "aws_lambda_permission" "tourist_api_gw_invoke" {
  statement_id  = "AllowExecutionFromAPIGatewayHTTP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tourist_http_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tourist_http_api.execution_arn}/*/*"
}
