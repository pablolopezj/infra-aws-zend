# Repositorio ECR para almacenar imágenes Docker
resource "aws_ecr_repository" "app" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id != "" ? var.kms_key_id : null
  }

  tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

# Política de lifecycle para limpiar imágenes antiguas
resource "aws_ecr_lifecycle_policy" "app" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images older than ${var.max_image_age_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.max_image_age_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Política de repositorio (opcional, para control de acceso)
resource "aws_ecr_repository_policy" "app" {
  count      = var.repository_policy != "" ? 1 : 0
  repository = aws_ecr_repository.app.name
  policy     = var.repository_policy
}

