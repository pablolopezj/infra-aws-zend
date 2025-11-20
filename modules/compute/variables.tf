variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be between 1 and 50 characters."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be launched"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach to the instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t4g.medium"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance. If not provided, will use latest Amazon Linux 2023 ARM64"
  default     = ""
}

variable "key_name" {
  type        = string
  description = "Name of the AWS key pair to use for SSH access"
  default     = ""
}

variable "monitoring_enabled" {
  type        = bool
  description = "Enable detailed CloudWatch monitoring"
  default     = false
}

variable "ebs_volume_size" {
  type        = number
  description = "Size of the EBS volume in GB"
  default     = 100

  validation {
    condition     = var.ebs_volume_size >= 1 && var.ebs_volume_size <= 16384
    error_message = "EBS volume size must be between 1 and 16384 GB."
  }
}

variable "ebs_volume_type" {
  type        = string
  description = "Type of EBS volume (gp3, gp2, io1, io2, etc.)"
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "st1", "sc1"], var.ebs_volume_type)
    error_message = "EBS volume type must be one of: gp3, gp2, io1, io2, st1, sc1."
  }
}

variable "ebs_iops" {
  type        = number
  description = "IOPS for gp3 volumes"
  default     = 3000

  validation {
    condition     = var.ebs_iops >= 3000 && var.ebs_iops <= 16000
    error_message = "IOPS for gp3 must be between 3000 and 16000."
  }
}

variable "ebs_throughput" {
  type        = number
  description = "Throughput in MB/s for gp3 volumes"
  default     = 125

  validation {
    condition     = var.ebs_throughput >= 125 && var.ebs_throughput <= 1000
    error_message = "Throughput for gp3 must be between 125 and 1000 MB/s."
  }
}

variable "enable_snapshots" {
  type        = number
  description = "Enable automatic snapshots (number of snapshots per day)"
  default     = 1

  validation {
    condition     = var.enable_snapshots >= 0 && var.enable_snapshots <= 24
    error_message = "Number of snapshots per day must be between 0 and 24."
  }
}

variable "snapshot_retention_days" {
  type        = number
  description = "Number of days to retain snapshots"
  default     = 7

  validation {
    condition     = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 365
    error_message = "Snapshot retention must be between 1 and 365 days."
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
}

variable "user_data" {
  type        = string
  description = "User data script to run on instance launch"
  default     = ""
}

