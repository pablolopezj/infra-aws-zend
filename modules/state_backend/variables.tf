variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket that stores terraform state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table used for state locking"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all state backend resources"
  default     = {}
}

