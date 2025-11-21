variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be between 1 and 50 characters."
  }
}

variable "enable_cloudwatch_metrics" {
  type        = bool
  description = "Enable CloudWatch metrics for WAF"
  default     = true
}

variable "enable_sampled_requests" {
  type        = bool
  description = "Enable sampled requests logging"
  default     = true
}

variable "enable_rate_limiting" {
  type        = bool
  description = "Enable rate limiting rule"
  default     = false
}

variable "rate_limit" {
  type        = number
  description = "Rate limit (requests per 5 minutes per IP)"
  default     = 2000

  validation {
    condition     = var.rate_limit > 0
    error_message = "Rate limit must be greater than 0."
  }
}

variable "allowed_ip_cidrs" {
  type        = list(string)
  description = "List of IP CIDR blocks to allow (empty = allow all)"
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ip_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP CIDR blocks must be valid."
  }
}

variable "blocked_ip_cidrs" {
  type        = list(string)
  description = "List of IP CIDR blocks to block"
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.blocked_ip_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP CIDR blocks must be valid."
  }
}

variable "custom_rules" {
  type = list(object({
    name         = string
    priority     = number
    type         = string # "ip_allow", "ip_block", "geo_block"
    action       = string # "allow", "block"
    ip_set_arn   = string
    country_codes = list(string)
  }))
  description = "Custom WAF rules"
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

