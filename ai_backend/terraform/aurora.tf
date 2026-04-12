resource "aws_rds_cluster" "aurora_v2" {
  cluster_identifier      = "${var.project_name}-${var.environment}-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "15.4" # يدعم pgvector
  database_name           = "tourism_ai"
  master_username         = "postgres"
  master_password         = "SuperSecretPassword123!" # In real env, use AWS Secrets Manager
  skip_final_snapshot     = true

  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_v2.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_v2.engine
  engine_version     = aws_rds_cluster.aurora_v2.engine_version
}
