variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be between 1 and 50 characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the bastion will be created"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID where the bastion will be launched"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block to allow bastion access to private instances"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for bastion host"
  default     = "t4g.micro"  # Pequeño y económico para ARM64

  validation {
    condition     = can(regex("^t[234]g?\\.(micro|small)$", var.instance_type))
    error_message = "Bastion instance type should be small (t3.micro, t4g.micro, etc.)"
  }
}

variable "key_name" {
  type        = string
  description = "AWS key pair name for SSH access"
  default     = ""
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to SSH to bastion (e.g., [\"1.2.3.4/32\"] for specific IP)"
  default     = ["0.0.0.0/0"]  # Por defecto permite desde cualquier lugar (ajustar según necesidad)

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "user_data" {
  type        = string
  description = "User data script to run on bastion launch"
  default     = ""
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

