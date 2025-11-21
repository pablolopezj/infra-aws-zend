# Web ACL para CloudFront
# NOTA: Este recurso DEBE crearse en us-east-1 cuando se invoca desde envs/prod
# El provider aws.us_east_1 se configura en envs/prod/providers.tf
resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${var.name_prefix}-waf-cloudfront"
  description = "WAF Web ACL for CloudFront distribution"
  scope       = "CLOUDFRONT" # Importante: debe ser CLOUDFRONT para CloudFront

  default_action {
    allow {}
  }

  # Regla 1: AWS Managed Rules - Core Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
      metric_name                = "${var.name_prefix}-CommonRuleSet"
      sampled_requests_enabled   = var.enable_sampled_requests
    }
  }

  # Regla 2: AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
      metric_name                = "${var.name_prefix}-KnownBadInputs"
      sampled_requests_enabled   = var.enable_sampled_requests
    }
  }

  # Regla 3: Rate Limiting (opcional)
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 3

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      action {
        block {}
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${var.name_prefix}-RateLimit"
        sampled_requests_enabled   = var.enable_sampled_requests
      }
    }
  }

  # Reglas personalizadas (si se especifican)
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.type == "ip_allow" || rule.value.type == "ip_block" ? [1] : []
          content {
            arn = rule.value.ip_set_arn
          }
        }

        dynamic "geo_match_statement" {
          for_each = rule.value.type == "geo_block" ? [1] : []
          content {
            country_codes = rule.value.country_codes
          }
        }
      }

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${var.name_prefix}-${rule.value.name}"
        sampled_requests_enabled   = var.enable_sampled_requests
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    metric_name                = "${var.name_prefix}-WAF"
    sampled_requests_enabled   = var.enable_sampled_requests
  }

  tags = var.tags
}

# IP Set para IPs permitidas (opcional)
resource "aws_wafv2_ip_set" "allowed_ips" {
  count = length(var.allowed_ip_cidrs) > 0 ? 1 : 0

  name               = "${var.name_prefix}-allowed-ips"
  description        = "IP addresses allowed to access the application"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_cidrs

  tags = var.tags
}

# IP Set para IPs bloqueadas (opcional)
resource "aws_wafv2_ip_set" "blocked_ips" {
  count = length(var.blocked_ip_cidrs) > 0 ? 1 : 0

  name               = "${var.name_prefix}-blocked-ips"
  description        = "IP addresses blocked from accessing the application"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_cidrs

  tags = var.tags
}

