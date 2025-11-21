output "distribution_id" {
  value       = aws_cloudfront_distribution.app.id
  description = "CloudFront distribution ID"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.app.arn
  description = "CloudFront distribution ARN"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.app.domain_name
  description = "CloudFront distribution domain name (e.g., d1234abcd.cloudfront.net)"
}

output "distribution_hosted_zone_id" {
  value       = aws_cloudfront_distribution.app.hosted_zone_id
  description = "Route 53 Hosted Zone ID for CloudFront"
}

output "distribution_status" {
  value       = aws_cloudfront_distribution.app.status
  description = "Current status of the distribution"
}

