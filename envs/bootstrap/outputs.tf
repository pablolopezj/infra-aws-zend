output "state_bucket" {
  value       = module.state_backend.bucket_id
  description = "Terraform state bucket name"
}

output "dynamodb_table" {
  value       = module.state_backend.dynamodb_table_id
  description = "Terraform lock DynamoDB table name"
}

