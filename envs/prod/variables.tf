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

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "project_name" {
  type        = string
  description = "Project name prefix for tagging"
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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 28
    error_message = "VPC CIDR prefix must be between /16 and /28."
  }
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block (e.g., 10.0.1.0/24)."
  }

  validation {
    condition     = tonumber(split("/", var.public_subnet_cidr)[1]) >= 16 && tonumber(split("/", var.public_subnet_cidr)[1]) <= 28
    error_message = "Public subnet CIDR prefix must be between /16 and /28."
  }
}

variable "public_subnet_az" {
  type        = string
  description = "Availability Zone for the public subnet"
  default     = "mx-central-1a"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+[a-z]$", var.public_subnet_az))
    error_message = "Availability Zone must be in the format 'region-zone' (e.g., mx-central-1a)."
  }
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block (e.g., 10.0.2.0/24)."
  }

  validation {
    condition     = tonumber(split("/", var.private_subnet_cidr)[1]) >= 16 && tonumber(split("/", var.private_subnet_cidr)[1]) <= 28
    error_message = "Private subnet CIDR prefix must be between /16 and /28."
  }
}

variable "private_subnet_az" {
  type        = string
  description = "Availability Zone for the private subnet"
  default     = "mx-central-1b"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+[a-z]$", var.private_subnet_az))
    error_message = "Availability Zone must be in the format 'region-zone' (e.g., mx-central-1b)."
  }
}

variable "enable_ec2_instance" {
  type        = bool
  description = "Enable EC2 instance creation"
  default     = true
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t4g.medium"
}

variable "ec2_key_name" {
  type        = string
  description = "AWS key pair name for SSH access to EC2 instance. If empty and create_key_pair=true, will use the created key pair"
  default     = "zend-app-key"
}

variable "create_key_pair" {
  type        = bool
  description = "Create a new key pair using Terraform"
  default     = false
}

variable "public_key_path" {
  type        = string
  description = "Path to the public key file (e.g., ~/.ssh/zend-app-key.pub). Required if create_key_pair=true"
  default     = ""
}

variable "ec2_subnet_tier" {
  type        = string
  description = "Subnet tier for EC2 instance (public or private)"
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.ec2_subnet_tier)
    error_message = "EC2 subnet tier must be either 'public' or 'private'."
  }
}

variable "enable_bastion" {
  type        = bool
  description = "Enable bastion host creation"
  default     = true
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for bastion host"
  default     = "t4g.micro"
}

variable "bastion_allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to bastion (use [\"1.2.3.4/32\"] for specific IP, [\"0.0.0.0/0\"] for anywhere)"
  default     = ["0.0.0.0/0"]
}