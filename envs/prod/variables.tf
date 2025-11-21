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

# ============================================================================
# Variables para RDS PostgreSQL
# ============================================================================

variable "enable_rds" {
  type        = bool
  description = "Enable RDS PostgreSQL instance creation"
  default     = true
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.medium"

  validation {
    condition     = can(regex("^db\\.(t[234]g?|r[456]g?)\\.", var.rds_instance_class))
    error_message = "RDS instance class must be a valid RDS instance type (e.g., db.t4g.medium)."
  }
}

variable "rds_allocated_storage" {
  type        = number
  description = "Allocated storage for RDS in GB"
  default     = 200

  validation {
    condition     = var.rds_allocated_storage >= 20 && var.rds_allocated_storage <= 65536
    error_message = "RDS allocated storage must be between 20 and 65536 GB."
  }
}

variable "rds_storage_type" {
  type        = string
  description = "RDS storage type (gp2, gp3, io1, io2)"
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.rds_storage_type)
    error_message = "RDS storage type must be one of: gp2, gp3, io1, io2."
  }
}

variable "rds_database_name" {
  type        = string
  description = "Name of the initial database"
  default     = "zenddb"

  validation {
    condition     = length(var.rds_database_name) >= 1 && length(var.rds_database_name) <= 63
    error_message = "Database name must be between 1 and 63 characters."
  }
}

variable "rds_master_username" {
  type        = string
  description = "Master username for RDS"
  default     = "postgres"

  validation {
    condition     = length(var.rds_master_username) >= 1 && length(var.rds_master_username) <= 16
    error_message = "Master username must be between 1 and 16 characters."
  }
}

variable "rds_master_password" {
  type        = string
  description = "Master password for RDS"
  sensitive   = true
  default     = "" # Debe ser proporcionado via terraform.tfvars o TF_VAR_rds_master_password

  validation {
    condition     = var.rds_master_password == "" || (length(var.rds_master_password) >= 8 && length(var.rds_master_password) <= 128)
    error_message = "RDS master password must be between 8 and 128 characters if provided."
  }
}

variable "rds_backup_retention_days" {
  type        = number
  description = "Number of days to retain automated backups (0-35)"
  default     = 7

  validation {
    condition     = var.rds_backup_retention_days >= 0 && var.rds_backup_retention_days <= 35
    error_message = "Backup retention days must be between 0 and 35."
  }
}

variable "rds_backup_window" {
  type        = string
  description = "Preferred backup window (UTC)"
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  type        = string
  description = "Preferred maintenance window (UTC)"
  default     = "sun:04:00-sun:05:00"
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying the RDS instance"
  default     = false
}

variable "rds_enable_performance_insights" {
  type        = bool
  description = "Enable Performance Insights for RDS"
  default     = false
}

variable "rds_monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval in seconds (0, 60, 300, 3600). 0 to disable"
  default     = 0

  validation {
    condition     = contains([0, 60, 300, 3600], var.rds_monitoring_interval)
    error_message = "Monitoring interval must be 0, 60, 300, or 3600 seconds."
  }
}

variable "rds_engine_version" {
  type        = string
  description = "PostgreSQL engine version (e.g., '16', '15', '14'). Leave empty for latest"
  default     = "16"
}

variable "rds_parameter_group_family" {
  type        = string
  description = "Parameter group family (e.g., 'postgres16', 'postgres15')"
  default     = "postgres16"
}

# ============================================================================
# Variables para S3
# ============================================================================

variable "enable_s3" {
  type        = bool
  description = "Enable S3 bucket creation for application"
  default     = true
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for the application"
  default     = "" # Se generará automáticamente si está vacío

  validation {
    condition     = var.s3_bucket_name == "" || (length(var.s3_bucket_name) >= 3 && length(var.s3_bucket_name) <= 63)
    error_message = "S3 bucket name must be between 3 and 63 characters if provided."
  }
}

variable "s3_enable_versioning" {
  type        = bool
  description = "Enable versioning for S3 bucket"
  default     = false
}

variable "s3_enable_lifecycle_transition" {
  type        = bool
  description = "Enable lifecycle transition to Glacier Instant Retrieval"
  default     = true
}

variable "s3_transition_to_glacier_ir_days" {
  type        = number
  description = "Number of days before transitioning objects to Glacier Instant Retrieval"
  default     = 30

  validation {
    condition     = var.s3_transition_to_glacier_ir_days > 0
    error_message = "Transition days must be greater than 0."
  }
}

variable "s3_transition_to_glacier_days" {
  type        = number
  description = "Number of days before transitioning objects to Glacier (0 to disable)"
  default     = 0
}

variable "s3_transition_to_deep_archive_days" {
  type        = number
  description = "Number of days before transitioning objects to Deep Archive (0 to disable)"
  default     = 0
}

variable "s3_noncurrent_version_transition_to_glacier_ir_days" {
  type        = number
  description = "Number of days before transitioning non-current versions to Glacier IR (0 to disable)"
  default     = 7

  validation {
    condition     = var.s3_noncurrent_version_transition_to_glacier_ir_days >= 0
    error_message = "Transition days must be 0 or greater."
  }
}

variable "s3_noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days before expiring non-current versions (0 to disable)"
  default     = 90

  validation {
    condition     = var.s3_noncurrent_version_expiration_days == 0 || var.s3_noncurrent_version_expiration_days >= var.s3_noncurrent_version_transition_to_glacier_ir_days
    error_message = "Expiration days must be 0 or greater than transition days."
  }
}

variable "create_ec2_s3_role" {
  type        = bool
  description = "Create IAM role and instance profile for EC2 to access S3"
  default     = true
}

variable "ec2_iam_role_arn" {
  type        = string
  description = "ARN of existing IAM role for EC2 to access S3 (if not creating new role)"
  default     = ""
}

# ============================================================================
# Variables para CloudFront + WAF + ALB
# ============================================================================

variable "enable_alb" {
  type        = bool
  description = "Enable Application Load Balancer. Required if EC2 is in private subnet. Optional if EC2 is in public subnet."
  default     = true
}

variable "enable_cloudfront" {
  type        = bool
  description = "Enable CloudFront distribution"
  default     = true
}

variable "enable_waf" {
  type        = bool
  description = "Enable WAF for CloudFront"
  default     = true
}

variable "cloudfront_price_class" {
  type        = string
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  default     = "PriceClass_100"
}

variable "cloudfront_default_root_object" {
  type        = string
  description = "Default root object for CloudFront (e.g., index.html)"
  default     = "index.html"
}

variable "waf_enable_rate_limiting" {
  type        = bool
  description = "Enable rate limiting in WAF"
  default     = false
}

variable "waf_rate_limit" {
  type        = number
  description = "WAF rate limit (requests per 5 minutes per IP)"
  default     = 2000
}

variable "alb_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS listener (empty = HTTP only)"
  default     = ""
}

variable "cloudfront_origin_s3_bucket" {
  type        = string
  description = "S3 bucket name to use as CloudFront origin (empty = use ALB or EC2). If set, CloudFront will point to S3 instead of ALB/EC2."
  default     = ""
}