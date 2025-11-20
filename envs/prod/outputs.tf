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

# Outputs de Compute (EC2)
output "ec2_instance_id" {
  value       = var.enable_ec2_instance ? module.compute[0].instance_id : null
  description = "ID of the EC2 instance"
}

output "ec2_instance_public_ip" {
  value       = var.enable_ec2_instance ? module.compute[0].instance_public_ip : null
  description = "Public IP address of the EC2 instance"
}

output "ec2_instance_private_ip" {
  value       = var.enable_ec2_instance ? module.compute[0].instance_private_ip : null
  description = "Private IP address of the EC2 instance"
}

output "ec2_ebs_volume_id" {
  value       = var.enable_ec2_instance ? module.compute[0].ebs_volume_id : null
  description = "ID of the attached EBS volume"
}

# Outputs de Bastion
output "bastion_public_ip" {
  value       = var.enable_bastion ? module.bastion[0].bastion_public_ip : null
  description = "Public IP address of the bastion host"
}

output "bastion_private_ip" {
  value       = var.enable_bastion ? module.bastion[0].bastion_private_ip : null
  description = "Private IP address of the bastion host"
}

output "bastion_instance_id" {
  value       = var.enable_bastion ? module.bastion[0].bastion_instance_id : null
  description = "ID of the bastion instance"
}

output "bastion_dns_name" {
  value       = var.enable_bastion ? module.bastion[0].bastion_dns_name : null
  description = "Public DNS name of the bastion host"
}