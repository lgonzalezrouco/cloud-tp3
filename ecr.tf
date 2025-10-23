# --- ECR Repository for Backend ---
resource "aws_ecr_repository" "backend" {
  name                 = "${lower(var.app_name)}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Application = var.app_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  # Prevent accidental deletion of ECR repository
  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# --- ECR Lifecycle Policy ---
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

