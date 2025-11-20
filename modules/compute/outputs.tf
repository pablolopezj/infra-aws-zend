output "instance_id" {
  value       = aws_instance.this.id
  description = "ID of the EC2 instance"
}

output "instance_arn" {
  value       = aws_instance.this.arn
  description = "ARN of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP address of the EC2 instance"
}

output "instance_private_ip" {
  value       = aws_instance.this.private_ip
  description = "Private IP address of the EC2 instance"
}

output "instance_availability_zone" {
  value       = aws_instance.this.availability_zone
  description = "Availability Zone of the EC2 instance"
}

output "ebs_volume_id" {
  value       = aws_ebs_volume.data.id
  description = "ID of the attached EBS volume"
}

output "ebs_volume_arn" {
  value       = aws_ebs_volume.data.arn
  description = "ARN of the attached EBS volume"
}

output "dlm_lifecycle_policy_id" {
  value       = var.enable_snapshots > 0 ? aws_dlm_lifecycle_policy.ebs_snapshots[0].id : null
  description = "ID of the Data Lifecycle Manager policy for snapshots"
}

