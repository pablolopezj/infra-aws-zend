output "bucket_id" {
  value       = aws_s3_bucket.state.id
  description = "ID of the Terraform state bucket"
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.locks.id
  description = "ID of the DynamoDB locking table"
}

