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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "ai_planner" {
  function_name = "${var.project_name}-planner-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "api.aws_websocket_handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 1024

  # ستحتاج إلى رفع الكود المصدري كحزمة ZIP أو Container Image
  # هذا مجرد Placeholder لأنك ستستخدم CI/CD للرفع
  s3_bucket = "dummy-bucket"
  s3_key    = "dummy-key"

  environment {
    variables = {
      WS_CONNECTIONS_TABLE = aws_dynamodb_table.ws_connections.name
      AURORA_HOST          = aws_rds_cluster.aurora_v2.endpoint
      AURORA_USER          = aws_rds_cluster.aurora_v2.master_username
      AURORA_PASS          = aws_rds_cluster.aurora_v2.master_password
      AURORA_DB            = aws_rds_cluster.aurora_v2.database_name
    }
  }
}
