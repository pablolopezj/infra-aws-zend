output "web_acl_id" {
  value       = aws_wafv2_web_acl.cloudfront.id
  description = "WAF Web ACL ID"
}

output "web_acl_arn" {
  value       = aws_wafv2_web_acl.cloudfront.arn
  description = "WAF Web ACL ARN"
}

output "web_acl_name" {
  value       = aws_wafv2_web_acl.cloudfront.name
  description = "WAF Web ACL name"
}

output "allowed_ip_set_id" {
  value       = length(aws_wafv2_ip_set.allowed_ips) > 0 ? aws_wafv2_ip_set.allowed_ips[0].id : null
  description = "IP Set ID for allowed IPs"
}

output "blocked_ip_set_id" {
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].id : null
  description = "IP Set ID for blocked IPs"
}

