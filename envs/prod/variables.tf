variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "mx-central-1" # Mexico Central
}

variable "short_region" {
  type        = string
  description = "Short code for region (for naming)"
  default     = "mxc1" # mx-central-1
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Project name prefix for tagging"
  default     = "zend-app"
}
