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

output "private_subnet_b_id" {
  value       = var.private_subnet_b_cidr != "" ? aws_subnet.private_b[0].id : null
  description = "ID of the second private subnet"
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

output "nat_gateway_id" {
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].id : null
  description = "ID of the NAT Gateway (if enabled)"
}

output "nat_gateway_public_ip" {
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
  description = "Public IP address of the NAT Gateway (if enabled)"
}

output "nat_gateway_eip_id" {
  value       = var.enable_nat_gateway ? aws_eip.nat[0].id : null
  description = "Elastic IP ID of the NAT Gateway (if enabled)"
}