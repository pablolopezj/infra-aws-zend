output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the created VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "ID of the public subnet"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "ID of the private subnet"
}

output "public_security_group_id" {
  value       = aws_security_group.public.id
  description = "ID of the public security group"
}

output "private_security_group_id" {
  value       = aws_security_group.private.id
  description = "ID of the private security group"
}

output "public_network_acl_id" {
  value       = aws_network_acl.public.id
  description = "ID of the public network ACL"
}

output "private_network_acl_id" {
  value       = aws_network_acl.private.id
  description = "ID of the private network ACL"
}

output "s3_vpc_endpoint_id" {
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
  description = "ID of the S3 VPC endpoint (if enabled)"
}

output "dynamodb_vpc_endpoint_id" {
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
  description = "ID of the DynamoDB VPC endpoint (if enabled)"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.this.id
  description = "ID of the Internet Gateway"
}