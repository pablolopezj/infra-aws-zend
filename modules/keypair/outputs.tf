output "key_name" {
  value       = aws_key_pair.this.key_name
  description = "Name of the AWS key pair"
}

output "key_pair_id" {
  value       = aws_key_pair.this.id
  description = "ID of the AWS key pair"
}

