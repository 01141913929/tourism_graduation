resource "aws_ecr_repository" "ai_backend_repo" {
  name                 = "${var.project_name}-repo-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.ai_backend_repo.repository_url
  description = "The URL of the ECR repository"
}

output "admin_ecr_url" {
  value = aws_ecr_repository.admin_ai_repo.repository_url
  description = "ECR for Admin Microservice"
}
