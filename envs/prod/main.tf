locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.short_region}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Region      = "mx-central-1"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"

  tags = local.common_tags
  name_prefix = local.name_prefix
}
