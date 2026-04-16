resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC Access (needed for Aurora Serverless private subnets)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# DynamoDB Full Access for sessions, carts, episodes, preferences, coupons
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-lambda-dynamodb"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          aws_dynamodb_table.ws_connections.arn,
          "${aws_dynamodb_table.ws_connections.arn}/index/*",
          aws_dynamodb_table.ai_sessions.arn,
          aws_dynamodb_table.user_preferences.arn,
          aws_dynamodb_table.ai_carts.arn,
          aws_dynamodb_table.ai_coupons.arn,
          aws_dynamodb_table.ai_episodes.arn,
        ]
      }
    ]
  })
}

# API Gateway Management — needed for sending WebSocket responses back to clients
resource "aws_iam_role_policy" "lambda_apigw_management" {
  name = "${var.project_name}-lambda-apigw-mgmt"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "execute-api:ManageConnections"
        Resource = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "ai_planner" {
  function_name = "${var.project_name}-planner-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.ai_backend_repo.repository_url}:latest"
  timeout       = 300
  memory_size   = 2048

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

      # --- API Keys (injected at deployment time, overridable via AWS Console) ---
      LLM_PROVIDER         = "groq"
      GROQ_API_KEY          = var.groq_api_key
      GROQ_API_KEY2         = var.groq_api_key_owner
      GROQ_API_KEY3         = var.groq_api_key_admin
      GEMINI_API_KEY        = var.gemini_api_key
      TAVILY_API_KEY        = var.tavily_api_key
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
    aws_iam_role_policy.lambda_apigw_management,
  ]
}

# ============================================================
# Variables for sensitive API keys (passed at deploy time)
# ============================================================
variable "groq_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "groq_api_key_owner" {
  type      = string
  sensitive = true
  default   = ""
}

variable "groq_api_key_admin" {
  type      = string
  sensitive = true
  default   = ""
}

variable "gemini_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tavily_api_key" {
  type      = string
  sensitive = true
  default   = ""
}
