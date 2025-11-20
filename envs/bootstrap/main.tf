locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "state_backend" {
  source = "../../modules/state_backend"

  bucket_name          = var.bucket_name
  dynamodb_table_name  = var.dynamodb_table_name
  tags                 = local.common_tags
}

