output "db_instance_id" {
  value       = aws_db_instance.this.id
  description = "RDS instance identifier"
}

output "db_instance_arn" {
  value       = aws_db_instance.this.arn
  description = "RDS instance ARN"
}

output "db_instance_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "RDS instance endpoint (hostname:port)"
}

output "db_instance_address" {
  value       = aws_db_instance.this.address
  description = "RDS instance hostname"
}

output "db_instance_port" {
  value       = aws_db_instance.this.port
  description = "RDS instance port"
}

output "db_instance_name" {
  value       = aws_db_instance.this.db_name
  description = "Name of the initial database"
}

output "db_instance_username" {
  value       = aws_db_instance.this.username
  description = "Master username"
  sensitive   = true
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.this.id
  description = "DB subnet group ID"
}

output "db_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Security Group ID for RDS"
}

output "db_parameter_group_id" {
  value       = aws_db_parameter_group.this.id
  description = "DB parameter group ID"
}

