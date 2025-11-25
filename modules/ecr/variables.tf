variable "repository_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository"
  default     = true
}

variable "encryption_type" {
  type        = string
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS"
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  type        = string
  description = "The KMS key to use when encryption_type is KMS. If not specified, uses the default AWS managed key for ECR"
  default     = ""
}

variable "enable_lifecycle_policy" {
  type        = bool
  description = "Enable lifecycle policy to automatically clean up old images"
  default     = true
}

variable "max_image_count" {
  type        = number
  description = "Maximum number of images to keep in the repository"
  default     = 10
}

variable "max_image_age_days" {
  type        = number
  description = "Maximum age in days for untagged images before they are expired"
  default     = 30
}

variable "repository_policy" {
  type        = string
  description = "JSON policy document to apply to the repository (optional). Leave empty for default policy"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource"
  default     = {}
}

