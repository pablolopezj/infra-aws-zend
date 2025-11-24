output "alb_id" {
  value       = aws_lb.app.id
  description = "ALB ID"
}

output "alb_arn" {
  value       = aws_lb.app.arn
  description = "ALB ARN"
}

output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "ALB DNS name (use this as CloudFront origin)"
}

output "alb_zone_id" {
  value       = aws_lb.app.zone_id
  description = "ALB hosted zone ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "Target group ARN"
}

output "security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security group ID for ALB"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security group ID for ALB (alias for compatibility)"
}

