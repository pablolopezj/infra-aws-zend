variable "key_name" {
  type        = string
  description = "Name of the AWS key pair"
}

variable "public_key" {
  type        = string
  description = "Public key content (from ~/.ssh/key.pub)"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the key pair"
  default     = {}
}

