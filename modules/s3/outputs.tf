output "bucket_id" {
  value       = aws_s3_bucket.app.id
  description = "Name (id) of the bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.app.arn
  description = "ARN of the bucket"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.app.bucket_domain_name
  description = "Bucket domain name"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.app.bucket_regional_domain_name
  description = "Bucket region-specific domain name"
}

output "bucket_hosted_zone_id" {
  value       = aws_s3_bucket.app.hosted_zone_id
  description = "Route 53 Hosted Zone ID for this bucket's region"
}

