# CloudFront Distribution
resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "CloudFront distribution for ${var.name_prefix}"
  default_root_object = var.default_root_object
  price_class         = var.price_class

  # Origen: ALB o directamente EC2
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = var.origin_http_port
      https_port             = var.origin_https_port
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = var.origin_ssl_protocols
    }

    # Custom headers (opcional)
    dynamic "custom_header" {
      for_each = var.custom_origin_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  # Comportamiento por defecto
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = var.origin_id
    compress         = var.enable_compression

    # WAF asociado
    web_acl_id = var.waf_web_acl_id != "" ? var.waf_web_acl_id : null

    # Política de caché
    cache_policy_id = var.cache_policy_id != "" ? var.cache_policy_id : "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingOptimized

    # Política de origen (para headers)
    origin_request_policy_id = var.origin_request_policy_id != "" ? var.origin_request_policy_id : "216adef6-5c79-47e5-8ff8-57738a87c925" # CORS-S3Origin

    # Viewer protocol policy
    viewer_protocol_policy = var.viewer_protocol_policy

    # Restricciones de viewer
    viewer_certificate {
      cloudfront_default_certificate = var.use_default_certificate
      acm_certificate_arn            = var.use_default_certificate ? null : var.acm_certificate_arn
      ssl_support_method             = var.use_default_certificate ? null : "sni-only"
      minimum_protocol_version       = var.use_default_certificate ? "TLSv1" : var.minimum_protocol_version
    }
  }

  # Restricciones geográficas (opcional)
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # Logging (opcional)
  dynamic "logging_config" {
    for_each = var.enable_logging && var.logging_bucket != "" ? [1] : []
    content {
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
      include_cookies = var.logging_include_cookies
    }
  }

  # Custom error responses (opcional)
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudfront"
    }
  )
}

