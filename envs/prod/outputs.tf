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
