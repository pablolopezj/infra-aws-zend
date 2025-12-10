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

output "nat_gateway_id" {
  value       = module.network.nat_gateway_id
  description = "ID of the NAT Gateway (if enabled)"
}

output "nat_gateway_public_ip" {
  value       = module.network.nat_gateway_public_ip
  description = "Public IP address of the NAT Gateway (if enabled)"
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

# ============================================================================
# Outputs de RDS PostgreSQL
# ============================================================================
# NOTA: Estos outputs están comentados porque el módulo RDS está comentado.
# Descomenta estos outputs cuando descomentes el módulo RDS en main.tf
#
# output "rds_instance_id" {
#   value       = var.enable_rds ? module.rds[0].db_instance_id : null
#   description = "RDS instance identifier"
# }
#
# output "rds_instance_endpoint" {
#   value       = var.enable_rds ? module.rds[0].db_instance_endpoint : null
#   description = "RDS instance endpoint (hostname:port)"
# }
#
# output "rds_instance_address" {
#   value       = var.enable_rds ? module.rds[0].db_instance_address : null
#   description = "RDS instance hostname"
# }
#
# output "rds_instance_port" {
#   value       = var.enable_rds ? module.rds[0].db_instance_port : null
#   description = "RDS instance port"
# }
#
# output "rds_database_name" {
#   value       = var.enable_rds ? module.rds[0].db_instance_name : null
#   description = "Name of the initial database"
# }
#
# output "rds_security_group_id" {
#   value       = var.enable_rds ? module.rds[0].db_security_group_id : null
#   description = "Security Group ID for RDS"
# }

# Outputs de S3
output "s3_bucket_id" {
  value       = var.enable_s3 ? module.s3[0].bucket_id : null
  description = "Name (id) of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = var.enable_s3 ? module.s3[0].bucket_arn : null
  description = "ARN of the S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = var.enable_s3 ? module.s3[0].bucket_domain_name : null
  description = "Domain name of the S3 bucket"
}

output "s3_bucket_regional_domain_name" {
  value       = var.enable_s3 ? module.s3[0].bucket_regional_domain_name : null
  description = "Region-specific domain name of the S3 bucket"
}

output "ec2_s3_role_arn" {
  value       = var.enable_ec2_instance && var.enable_s3 && var.create_ec2_s3_role ? aws_iam_role.ec2_s3_access[0].arn : null
  description = "ARN of the IAM role for EC2 to access S3"
}

# ============================================================================
# Outputs de ALB
# ============================================================================
output "alb_dns_name" {
  value       = var.enable_alb && var.enable_cloudfront ? module.alb[0].alb_dns_name : null
  description = "DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = var.enable_alb && var.enable_cloudfront ? module.alb[0].alb_arn : null
  description = "ARN of the Application Load Balancer"
}

output "alb_target_group_arn" {
  value       = var.enable_alb && var.enable_cloudfront ? module.alb[0].target_group_arn : null
  description = "ARN of the ALB target group"
}

output "alb_security_group_id" {
  value       = var.enable_alb && var.enable_cloudfront ? module.alb[0].security_group_id : null
  description = "Security group ID of the ALB"
}

# ============================================================================
# Outputs de WAF
# ============================================================================
output "waf_web_acl_id" {
  value       = var.enable_waf && var.enable_cloudfront ? module.waf[0].web_acl_id : null
  description = "WAF Web ACL ID"
}

output "waf_web_acl_arn" {
  value       = var.enable_waf && var.enable_cloudfront ? module.waf[0].web_acl_arn : null
  description = "WAF Web ACL ARN"
}

# ============================================================================
# Outputs de CloudFront
# ============================================================================
output "cloudfront_distribution_id" {
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_id : null
  description = "CloudFront distribution ID"
}

output "cloudfront_distribution_domain_name" {
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_domain_name : null
  description = "CloudFront distribution domain name (use this URL to access your application)"
}

output "cloudfront_distribution_arn" {
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_arn : null
  description = "CloudFront distribution ARN"
}

# ============================================================================
# Outputs de ECR
# ============================================================================
output "ecr_repository_url" {
  value       = var.enable_ecr ? module.ecr[0].repository_url : null
  description = "URL of the ECR repository (use this to push/pull Docker images)"
}

output "ecr_repository_name" {
  value       = var.enable_ecr ? module.ecr[0].repository_name : null
  description = "Name of the ECR repository"
}

output "ecr_repository_arn" {
  value       = var.enable_ecr ? module.ecr[0].repository_arn : null
  description = "ARN of the ECR repository"
}

output "ecr_registry_id" {
  value       = var.enable_ecr ? module.ecr[0].registry_id : null
  description = "Registry ID where the repository was created"
}