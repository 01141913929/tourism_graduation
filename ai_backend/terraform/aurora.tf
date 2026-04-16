resource "aws_security_group" "aurora_sg" {
  name        = "${var.project_name}-aurora-sg"
  description = "Allow inbound postgres traffic"

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "aurora_v2" {
  cluster_identifier      = "${var.project_name}-${var.environment}-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  database_name           = "tourism_ai"
  master_username         = "postgres"
  master_password         = "SuperSecretPassword123!" # In real env, use AWS Secrets Manager
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]

  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier  = aws_rds_cluster.aurora_v2.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora_v2.engine
  publicly_accessible = true
}
