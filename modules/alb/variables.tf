variable "name_prefix" {
  type        = string
  description = "Naming convention prefix for all resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the ALB (must be in public subnets)"
}

variable "internal" {
  type        = bool
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  default     = false
}

variable "target_instance_ids" {
  type        = list(string)
  description = "List of EC2 instance IDs to register in the target group"
  default     = []
}

variable "target_port" {
  type        = number
  description = "Port on which targets receive traffic"
  default     = 80
}

variable "target_protocol" {
  type        = string
  description = "Protocol to use for routing traffic to targets"
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "Target protocol must be HTTP or HTTPS."
  }
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "health_check_protocol" {
  type        = string
  description = "Health check protocol"
  default     = "HTTP"
}

variable "health_check_matcher" {
  type        = string
  description = "HTTP codes to use when checking for a healthy response"
  default     = "200"
}

variable "health_check_interval" {
  type        = number
  description = "Health check interval in seconds"
  default     = 30
}

variable "health_check_timeout" {
  type        = number
  description = "Health check timeout in seconds"
  default     = 5
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Number of consecutive health checks successes required"
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Number of consecutive health check failures required"
  default     = 2
}

variable "deregistration_delay" {
  type        = number
  description = "Amount of time for connections to drain on target deregistration"
  default     = 300
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener (empty string = no HTTPS)"
  default     = ""
  
  validation {
    condition     = var.certificate_arn == "" || can(regex("^arn:aws:acm:", var.certificate_arn))
    error_message = "Certificate ARN must be a valid ACM ARN or empty string."
  }
}

variable "ssl_policy" {
  type        = string
  description = "SSL policy for HTTPS listener"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for the ALB"
  default     = false
}

variable "enable_http2" {
  type        = bool
  description = "Enable HTTP/2"
  default     = true
}

variable "enable_access_logs" {
  type        = bool
  description = "Enable access logs"
  default     = false
}

variable "access_logs_bucket" {
  type        = string
  description = "S3 bucket for access logs"
  default     = ""
}

variable "access_logs_prefix" {
  type        = string
  description = "Prefix for access logs"
  default     = "alb-logs/"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access the ALB"
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}

