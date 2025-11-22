variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.bucket_name))
    error_message = "S3 bucket name can only contain lowercase letters, numbers, dots, and hyphens."
  }
}

variable "enable_versioning" {
  type        = bool
  description = "Enable versioning for the bucket"
  default     = true
}

variable "enable_lifecycle_transition" {
  type        = bool
  description = "Enable lifecycle transition to Glacier Instant Retrieval"
  default     = true
}

variable "transition_to_glacier_ir_days" {
  type        = number
  description = "Number of days before transitioning objects to Glacier Instant Retrieval"
  default     = 30

  validation {
    condition     = var.transition_to_glacier_ir_days > 0
    error_message = "Transition days must be greater than 0."
  }
}

variable "transition_to_glacier_days" {
  type        = number
  description = "Number of days before transitioning objects to Glacier (0 to disable)"
  default     = 0
}

variable "transition_to_deep_archive_days" {
  type        = number
  description = "Number of days before transitioning objects to Deep Archive (0 to disable)"
  default     = 0
}

variable "noncurrent_version_transition_to_glacier_ir_days" {
  type        = number
  description = "Number of days before transitioning non-current versions to Glacier IR (0 to disable)"
  default     = 7

  validation {
    condition     = var.noncurrent_version_transition_to_glacier_ir_days >= 0
    error_message = "Transition days must be 0 or greater."
  }
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days before expiring non-current versions (0 to disable)"
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days == 0 || var.noncurrent_version_expiration_days >= var.noncurrent_version_transition_to_glacier_ir_days
    error_message = "Expiration days must be 0 or greater than transition days."
  }
}

variable "allowed_principal_arns" {
  type        = list(string)
  description = "List of IAM principal ARNs allowed to access the bucket (e.g., EC2 instance role ARN)"
  default     = []
}

variable "cloudfront_oai_iam_arn" {
  type        = string
  description = "IAM ARN of CloudFront Origin Access Identity (OAI) for secure S3 access via CloudFront. Leave empty to disable OAI access."
  default     = ""
}

variable "enable_logging" {
  type        = bool
  description = "Enable access logging for the bucket"
  default     = false
}

variable "logging_target_bucket" {
  type        = string
  description = "Target bucket for access logs"
  default     = ""
}

variable "logging_target_prefix" {
  type        = string
  description = "Prefix for access logs"
  default     = "logs/"
}

variable "cors_rules" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  description = "List of CORS rules for the bucket"
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

