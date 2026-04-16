resource "aws_ecr_repository" "admin_ai_repo" {
  name                 = "admin-ai-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true # يسمح بالحذف حتى لو فيه صور
}

# HTTP API Gateway for Admin
resource "aws_apigatewayv2_api" "admin_http_api" {
  name          = "admin-ai-http-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# The Lambda Function for Admin Service
resource "aws_lambda_function" "admin_lambda" {
  function_name = "admin-ai-service"
  role          = aws_iam_role.admin_lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.admin_ai_repo.repository_url}:latest"
  
  timeout     = 120 # 2 minutes (Admin queries might be heavy, BI reports)
  memory_size = 2048

  environment {
    variables = {
      # API Keys
      GROQ_API_KEY       = var.groq_api_key
      GROQ_API_KEY2      = var.groq_api_key_owner
      GROQ_API_KEY3      = var.groq_api_key_admin
      GEMINI_API_KEY     = var.gemini_api_key
      TAVILY_API_KEY     = var.tavily_api_key
      
      # DB Constants
      AURORA_HOST        = aws_rds_cluster.aurora_v2.endpoint
      AURORA_USER        = aws_rds_cluster.aurora_v2.master_username
      AURORA_PASS        = aws_rds_cluster.aurora_v2.master_password
      AURORA_DB          = aws_rds_cluster.aurora_v2.database_name
      
      # DynamoDB Tables
      WS_CONNECTIONS_TABLE = aws_dynamodb_table.ws_connections.name
      SESSIONS_TABLE     = aws_dynamodb_table.ai_sessions.name
      PREFERENCES_TABLE  = aws_dynamodb_table.user_preferences.name
      
      # Model Settings
      LLM_PROVIDER       = "groq"
      LOG_LEVEL          = "INFO"
      
      # Langfuse Observability
      LANGFUSE_SECRET_KEY = "sk-lf-71e04a77-f388-45de-8cb3-7941132e6a77"
      LANGFUSE_PUBLIC_KEY = "pk-lf-ee2c3ee3-d115-49de-bab1-9d6264d289e0"
      LANGFUSE_BASE_URL   = "https://cloud.langfuse.com"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.admin_lambda_basic,
    aws_iam_role_policy_attachment.admin_lambda_vpc,
    aws_iam_role_policy.admin_lambda_dynamodb,
    aws_ecr_repository.admin_ai_repo
  ]
}

# API Gateway integration with Admin Lambda
resource "aws_apigatewayv2_integration" "admin_lambda_integration" {
  api_id             = aws_apigatewayv2_api.admin_http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.admin_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "admin_default_route" {
  api_id    = aws_apigatewayv2_api.admin_http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.admin_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "admin_prod_stage" {
  api_id      = aws_apigatewayv2_api.admin_http_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "admin_api_gw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.admin_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.admin_http_api.execution_arn}/*/*"
}

# IAM Role for Admin Service
resource "aws_iam_role" "admin_lambda_role" {
  name = "admin_ai_lambda_role"

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

# Shared Policies
resource "aws_iam_role_policy_attachment" "admin_lambda_basic" {
  role       = aws_iam_role.admin_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "admin_lambda_vpc" {
  role       = aws_iam_role.admin_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "admin_lambda_dynamodb" {
  name = "admin_ai_dynamodb_policy"
  role = aws_iam_role.admin_lambda_role.id
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
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.ws_connections.arn,
          "${aws_dynamodb_table.ws_connections.arn}/index/*",
          aws_dynamodb_table.ai_sessions.arn,
          aws_dynamodb_table.user_preferences.arn,
          aws_dynamodb_table.ai_carts.arn,
          aws_dynamodb_table.ai_coupons.arn,
          aws_dynamodb_table.ai_episodes.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ],
        Resource = "*"
      }
    ]
  })
}
