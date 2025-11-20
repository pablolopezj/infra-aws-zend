output "bastion_instance_id" {
  value       = aws_instance.this.id
  description = "ID of the bastion instance"
}

output "bastion_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP address of the bastion host"
}

output "bastion_private_ip" {
  value       = aws_instance.this.private_ip
  description = "Private IP address of the bastion host"
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion.id
  description = "ID of the bastion security group"
}

output "bastion_dns_name" {
  value       = aws_instance.this.public_dns
  description = "Public DNS name of the bastion host"
}

