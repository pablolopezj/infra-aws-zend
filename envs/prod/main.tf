locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.short_region}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Region      = "mx-central-1"
    ManagedBy   = "terraform"
  }
}

# Key Pair para acceso SSH (opcional)
module "keypair" {
  count  = var.create_key_pair && var.public_key_path != "" ? 1 : 0
  source = "../../modules/keypair"

  key_name   = "${local.name_prefix}-key"
  public_key = file(var.public_key_path)
  tags       = local.common_tags
}

module "network" {
  source = "../../modules/network"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  public_subnet_az    = var.public_subnet_az
  private_subnet_cidr = var.private_subnet_cidr
  private_subnet_az   = var.private_subnet_az

  tags        = local.common_tags
  name_prefix = local.name_prefix
}

# Módulo de Compute (EC2)
module "compute" {
  count  = var.enable_ec2_instance ? 1 : 0
  source = "../../modules/compute"

  name_prefix = local.name_prefix

  # Seleccionar subnet según el tier especificado
  subnet_id = var.ec2_subnet_tier == "public" ? module.network.public_subnet_id : module.network.private_subnet_id

  # Seleccionar security group según el tier
  security_group_ids = var.ec2_subnet_tier == "public" ? [module.network.public_security_group_id] : [module.network.private_security_group_id]

  instance_type = var.ec2_instance_type
  # Usar key pair creado por Terraform o el especificado manualmente
  key_name = var.ec2_key_name != "" ? var.ec2_key_name : (var.create_key_pair && var.public_key_path != "" ? module.keypair[0].key_name : null)

  # Configuración de EBS según especificaciones
  ebs_volume_size     = 100
  ebs_volume_type     = "gp3"
  ebs_iops            = 3000
  ebs_throughput      = 125
  enable_snapshots    = 1  # 1 vez al día
  snapshot_retention_days = 7

  # Monitorización desactivada
  monitoring_enabled = false

  tags = local.common_tags
}

# Bastion Host
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "../../modules/bastion"

  name_prefix = local.name_prefix

  vpc_id     = module.network.vpc_id
  subnet_id  = module.network.public_subnet_id
  vpc_cidr   = var.vpc_cidr

  instance_type = var.bastion_instance_type
  key_name      = var.ec2_key_name != "" ? var.ec2_key_name : (var.create_key_pair && var.public_key_path != "" ? module.keypair[0].key_name : null)

  allowed_ssh_cidrs = var.bastion_allowed_ssh_cidrs

  tags = local.common_tags
}

# ============================================================================
# Módulo de RDS PostgreSQL
# ============================================================================
# NOTA: Este módulo está comentado temporalmente. Para activarlo:
# 1. Descomenta el bloque de código siguiente
# 2. Asegúrate de tener configurado rds_master_password en terraform.tfvars
# 3. Ejecuta: terraform init && terraform plan && terraform apply
#
# module "rds" {
#   count  = var.enable_rds ? 1 : 0
#   source = "../../modules/rds"
#
#   name_prefix = local.name_prefix
#
#   vpc_id     = module.network.vpc_id
#   vpc_cidr   = var.vpc_cidr
#   subnet_ids = [module.network.private_subnet_id] # RDS en subnet privada
#   availability_zone = var.private_subnet_az # Single-AZ deployment
#
#   instance_class    = var.rds_instance_class
#   allocated_storage = var.rds_allocated_storage
#   storage_type      = var.rds_storage_type
#
#   database_name  = var.rds_database_name
#   master_username = var.rds_master_username
#   master_password = var.rds_master_password != "" ? var.rds_master_password : (var.enable_rds ? error("rds_master_password must be provided when enable_rds is true") : "")
#
#   engine_version         = var.rds_engine_version
#   parameter_group_family = var.rds_parameter_group_family
#
#   # Permitir acceso desde la instancia EC2 privada
#   allowed_security_group_ids = var.enable_ec2_instance && var.ec2_subnet_tier == "private" ? [module.network.private_security_group_id] : []
#
#   backup_retention_days = var.rds_backup_retention_days
#   backup_window         = var.rds_backup_window
#   maintenance_window    = var.rds_maintenance_window
#   skip_final_snapshot   = var.rds_skip_final_snapshot
#
#   enable_performance_insights = var.rds_enable_performance_insights
#   monitoring_interval         = var.rds_monitoring_interval
#
#   tags = local.common_tags
# }
