output "vpc_id" {
  value       = module.network.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "ID of the public subnet"
}

output "private_subnet_id" {
  value       = module.network.private_subnet_id
  description = "ID of the private subnet"
}

output "public_security_group_id" {
  value       = module.network.public_security_group_id
  description = "ID of the public security group"
}

output "private_security_group_id" {
  value       = module.network.private_security_group_id
  description = "ID of the private security group"
}

output "public_network_acl_id" {
  value       = module.network.public_network_acl_id
  description = "ID of the public network ACL"
}

output "private_network_acl_id" {
  value       = module.network.private_network_acl_id
  description = "ID of the private network ACL"
}

output "s3_vpc_endpoint_id" {
  value       = module.network.s3_vpc_endpoint_id
  description = "ID of the S3 VPC endpoint"
}

output "dynamodb_vpc_endpoint_id" {
  value       = module.network.dynamodb_vpc_endpoint_id
  description = "ID of the DynamoDB VPC endpoint"
}

output "internet_gateway_id" {
  value       = module.network.internet_gateway_id
  description = "ID of the Internet Gateway"
}