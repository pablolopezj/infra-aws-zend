variable "aws_region" {
  type        = string
  description = "AWS region to provision Terraform backend resources"
  default     = "mx-central-1"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
  default     = "zend-terraform-state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
  default     = "zend-terraform-locks"
}

variable "project_name" {
  type        = string
  description = "Project identifier for tagging"
  default     = "zend-app"
}

variable "environment" {
  type        = string
  description = "Environment identifier for tagging"
  default     = "bootstrap"
}

