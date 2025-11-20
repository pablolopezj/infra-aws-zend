variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"

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

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+[a-z]$", var.public_subnet_az))
    error_message = "Availability Zone must be in the format 'region-zone' (e.g., mx-central-1a)."
  }
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"

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

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+[a-z]$", var.private_subnet_az))
    error_message = "Availability Zone must be in the format 'region-zone' (e.g., mx-central-1b)."
  }
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

  validation {
    condition = alltrue([
      for k, v in var.tags : length(v) <= 256
    ])
    error_message = "Tag values must be 256 characters or less."
  }

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$", k))
    ])
    error_message = "Tag keys can contain letters, numbers, spaces, and these characters: _.:/=+-@"
  }
}

variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be between 1 and 50 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "enable_vpc_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for S3 and DynamoDB to minimize external traffic"
  default     = true
}

variable "allowed_public_ingress_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access public subnet resources"
  default     = ["0.0.0.0/0"]
}

variable "allowed_public_ingress_ports" {
  type        = list(number)
  description = "List of ports allowed for ingress in public subnet (e.g., [80, 443])"
  default     = [80, 443]
}



