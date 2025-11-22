# Origin Access Identity para S3 (solo si es origen S3 y no se proporciona uno existente)
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  count   = var.origin_type == "s3" && var.s3_origin_access_identity == "" ? 1 : 0
  comment = "OAI for ${var.name_prefix} CloudFront distribution"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "CloudFront distribution for ${var.name_prefix}"
  default_root_object = var.default_root_object
  price_class         = var.price_class

  # WAF asociado (a nivel de distribución)
  # NOTA: CloudFront puede usar WAFs de us-east-1 (requerido para scope CLOUDFRONT)
  # El WAF debe estar creado antes de asociarlo a CloudFront
  # IMPORTANTE: Aunque el parámetro se llama "web_acl_id", CloudFront requiere el ARN completo, no el ID
  web_acl_id = var.waf_web_acl_id != "" && var.waf_web_acl_id != null ? var.waf_web_acl_id : null

  # Origen: S3 o Custom (ALB/EC2)
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    # Configuración para origen S3
    dynamic "s3_origin_config" {
      for_each = var.origin_type == "s3" ? [1] : []
      content {
        origin_access_identity = var.s3_origin_access_identity != "" ? var.s3_origin_access_identity : (
          length(aws_cloudfront_origin_access_identity.s3_oai) > 0 ? aws_cloudfront_origin_access_identity.s3_oai[0].cloudfront_access_identity_path : ""
        )
      }
    }

    # Configuración para origen Custom (ALB/EC2)
    dynamic "custom_origin_config" {
      for_each = var.origin_type == "custom" ? [1] : []
      content {
        http_port              = var.origin_http_port
        https_port            = var.origin_https_port
        origin_protocol_policy = var.origin_protocol_policy
        origin_ssl_protocols   = var.origin_ssl_protocols
      }
    }

    # Custom headers (solo para custom origin)
    dynamic "custom_header" {
      for_each = var.origin_type == "custom" ? var.custom_origin_headers : []
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

    # Política de caché (usar la proporcionada o default administrada)
    cache_policy_id = var.cache_policy_id != "" ? var.cache_policy_id : "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingOptimized

    # Política de origen (mejor AllViewer para custom origin; ajusta si quieres otra)
    origin_request_policy_id = var.origin_request_policy_id != "" ? var.origin_request_policy_id : "b689b0a8-53d0-40ab-baf2-68738e2966ac" # Managed-AllViewer

    # Viewer protocol policy
    viewer_protocol_policy = var.viewer_protocol_policy
  }

  # Certificado del viewer (nivel de distribución, NO dentro de default_cache_behavior)
  viewer_certificate {
    # Si usas el certificado por defecto de CloudFront (*.cloudfront.net)
    cloudfront_default_certificate = var.use_default_certificate ? true : false

    # Si usas dominio propio, se espera que use_default_certificate = false
    # Solo incluir estos campos si NO se usa el certificado por defecto
    acm_certificate_arn      = var.use_default_certificate ? null : (var.acm_certificate_arn != "" ? var.acm_certificate_arn : null)
    ssl_support_method       = var.use_default_certificate ? null : (var.acm_certificate_arn != "" ? "sni-only" : null)
    minimum_protocol_version = var.use_default_certificate ? null : var.minimum_protocol_version
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
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
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
