variable "aws_region" {
  type        = string
  description = "AWS region to provision Terraform backend resources"
  default     = "mx-central-1"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
  default     = "zend-terraform-state"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$", var.bucket_name))
    error_message = "S3 bucket name must contain only lowercase letters, numbers, and hyphens. Must start and end with a letter or number."
  }
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
  default     = "zend-terraform-locks"

  validation {
    condition     = length(var.dynamodb_table_name) >= 3 && length(var.dynamodb_table_name) <= 255
    error_message = "DynamoDB table name must be between 3 and 255 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+$", var.dynamodb_table_name))
    error_message = "DynamoDB table name can contain only letters, numbers, underscores, hyphens, and dots."
  }
}

variable "project_name" {
  type        = string
  description = "Project identifier for tagging"
  default     = "zend-app"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment identifier for tagging"
  default     = "bootstrap"
}

