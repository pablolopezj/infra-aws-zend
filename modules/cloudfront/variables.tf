variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be between 1 and 50 characters."
  }
}

variable "origin_domain_name" {
  type        = string
  description = "Domain name of the origin (ALB DNS name or EC2 endpoint)"
}

variable "origin_id" {
  type        = string
  description = "Unique identifier for the origin"
  default     = "default-origin"
}

variable "origin_http_port" {
  type        = number
  description = "HTTP port for custom origin"
  default     = 80
}

variable "origin_https_port" {
  type        = number
  description = "HTTPS port for custom origin"
  default     = 443
}

variable "origin_protocol_policy" {
  type        = string
  description = "Origin protocol policy (http-only, https-only, match-viewer)"
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.origin_protocol_policy)
    error_message = "Origin protocol policy must be one of: http-only, https-only, match-viewer."
  }
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "SSL protocols supported by origin"
  default     = ["TLSv1.2"]
}

variable "custom_origin_headers" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Custom headers to send to origin"
  default     = []
}

variable "allowed_methods" {
  type        = list(string)
  description = "HTTP methods allowed by CloudFront"
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
  type        = list(string)
  description = "HTTP methods that are cached"
  default     = ["GET", "HEAD"]
}

variable "enable_compression" {
  type        = bool
  description = "Enable compression for supported content types"
  default     = true
}

variable "waf_web_acl_id" {
  type        = string
  description = "WAF Web ACL ID to associate with CloudFront"
  default     = ""
}

variable "cache_policy_id" {
  type        = string
  description = "Cache policy ID (empty = use default)"
  default     = ""
}

variable "origin_request_policy_id" {
  type        = string
  description = "Origin request policy ID (empty = use default)"
  default     = ""
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy (allow-all, https-only, redirect-to-https)"
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be one of: allow-all, https-only, redirect-to-https."
  }
}

variable "use_default_certificate" {
  type        = bool
  description = "Use CloudFront default certificate (cloudfront.net domain)"
  default     = true
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for custom domain (required if use_default_certificate=false)"
  default     = ""
}

variable "minimum_protocol_version" {
  type        = string
  description = "Minimum SSL/TLS protocol version"
  default     = "TLSv1.2_2021"
}

variable "default_root_object" {
  type        = string
  description = "Default root object (e.g., index.html)"
  default     = "index.html"
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable IPv6"
  default     = true
}

variable "price_class" {
  type        = string
  description = "Price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "geo_restriction_type" {
  type        = string
  description = "Geo restriction type (none, whitelist, blacklist)"
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "geo_restriction_locations" {
  type        = list(string)
  description = "List of country codes for geo restriction"
  default     = []
}

variable "enable_logging" {
  type        = bool
  description = "Enable CloudFront access logging"
  default     = false
}

variable "logging_bucket" {
  type        = string
  description = "S3 bucket for CloudFront access logs"
  default     = ""
}

variable "logging_prefix" {
  type        = string
  description = "Prefix for CloudFront access logs"
  default     = "cloudfront-logs/"
}

variable "logging_include_cookies" {
  type        = bool
  description = "Include cookies in access logs"
  default     = false
}

variable "custom_error_responses" {
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  description = "Custom error responses"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : length(k) > 0 && length(k) <= 128
    ])
    error_message = "Tag keys must be between 1 and 128 characters."
  }
}

