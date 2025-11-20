variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "public_subnet_az" {
  type        = string
  description = "Availability Zone for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}

variable "private_subnet_az" {
  type        = string
  description = "Availability Zone for the private subnet"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"
}



