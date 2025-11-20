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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet_az" {
  type        = string
  description = "Availability Zone for the public subnet"
  default     = "mx-central-1a"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "private_subnet_az" {
  type        = string
  description = "Availability Zone for the private subnet"
  default     = "mx-central-1b"
}