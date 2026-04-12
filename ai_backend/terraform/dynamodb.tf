resource "aws_dynamodb_table" "ws_connections" {
  name           = "AiConnections"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ConnectionId"

  attribute {
    name = "ConnectionId"
    type = "S"
  }
  
  attribute {
    name = "SessionId"
    type = "S"
  }

  global_secondary_index {
    name               = "SessionIndex"
    hash_key           = "SessionId"
    projection_type    = "ALL"
  }
}

resource "aws_dynamodb_table" "ai_sessions" {
  name           = "AiSessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "SessionId"

  attribute {
    name = "SessionId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user_preferences" {
  name           = "UserPreferences"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "ai_carts" {
  name           = "AiCarts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "ai_coupons" {
  name           = "AiCoupons"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Code"

  attribute {
    name = "Code"
    type = "S"
  }
}

resource "aws_dynamodb_table" "ai_episodes" {
  name           = "AiEpisodes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"
  range_key      = "Timestamp"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }
}
