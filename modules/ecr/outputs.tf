output "repository_id" {
  value       = aws_ecr_repository.app.id
  description = "ID of the ECR repository"
}

output "repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "ARN of the ECR repository"
}

output "repository_name" {
  value       = aws_ecr_repository.app.name
  description = "Name of the ECR repository"
}

output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL of the ECR repository (use this to push/pull images)"
}

output "registry_id" {
  value       = aws_ecr_repository.app.registry_id
  description = "Registry ID where the repository was created"
}

