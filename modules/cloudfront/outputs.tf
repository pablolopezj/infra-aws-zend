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

output "origin_access_identity_iam_arn" {
  value       = var.origin_type == "s3" && var.s3_origin_access_identity == "" ? aws_cloudfront_origin_access_identity.s3_oai[0].iam_arn : null
  description = "IAM ARN of the Origin Access Identity (for S3 bucket policy)"
}

output "origin_access_identity_path" {
  value       = var.origin_type == "s3" && var.s3_origin_access_identity == "" ? aws_cloudfront_origin_access_identity.s3_oai[0].cloudfront_access_identity_path : null
  description = "Path of the Origin Access Identity (for S3 bucket policy)"
}

