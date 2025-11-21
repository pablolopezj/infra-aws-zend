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
  description = "VPC ID where RDS will be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for security group rules"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the DB subnet group (should be private subnets)"
}

variable "availability_zone" {
  type        = string
  description = "Availability Zone for the RDS instance (Single-AZ deployment)"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.medium"

  validation {
    condition     = can(regex("^db\\.(t[234]g?|r[456]g?)\\.", var.instance_class))
    error_message = "Instance class must be a valid RDS instance type (e.g., db.t4g.medium)."
  }
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 200

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for autoscaling (0 to disable)"
  default     = 0

  validation {
    condition     = var.max_allocated_storage == 0 || (var.max_allocated_storage >= var.allocated_storage && var.max_allocated_storage <= 65536)
    error_message = "Max allocated storage must be 0 (disabled) or between allocated_storage and 65536 GB."
  }
}

variable "storage_type" {
  type        = string
  description = "Storage type (gp2, gp3, io1, io2)"
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2."
  }
}

variable "database_name" {
  type        = string
  description = "Name of the initial database"
  default     = "zenddb"

  validation {
    condition     = length(var.database_name) >= 1 && length(var.database_name) <= 63
    error_message = "Database name must be between 1 and 63 characters."
  }
}

variable "master_username" {
  type        = string
  description = "Master username for the database"
  default     = "postgres"

  validation {
    condition     = length(var.master_username) >= 1 && length(var.master_username) <= 16
    error_message = "Master username must be between 1 and 16 characters."
  }
}

variable "master_password" {
  type        = string
  description = "Master password for the database"
  sensitive   = true

  validation {
    condition     = length(var.master_password) >= 8 && length(var.master_password) <= 128
    error_message = "Master password must be between 8 and 128 characters."
  }
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "List of Security Group IDs allowed to access RDS (e.g., EC2 instance security groups)"
  default     = []
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain automated backups (0-35)"
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 0 and 35."
  }
}

variable "backup_window" {
  type        = string
  description = "Preferred backup window (UTC)"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window (UTC)"
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying the instance"
  default     = false
}

variable "enable_performance_insights" {
  type        = bool
  description = "Enable Performance Insights"
  default     = false
}

variable "monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval in seconds (0, 60, 300, 3600). 0 to disable"
  default     = 0

  validation {
    condition     = contains([0, 60, 300, 3600], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 60, 300, or 3600 seconds."
  }
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version (e.g., '16', '15', '14'). Leave empty for latest"
  default     = "16"
}

variable "parameter_group_family" {
  type        = string
  description = "Parameter group family (e.g., 'postgres16', 'postgres15')"
  default     = "postgres16"
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

