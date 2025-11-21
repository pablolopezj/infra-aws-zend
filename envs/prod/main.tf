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

# IAM Role para EC2 para acceder a S3 (debe crearse antes del módulo compute)
resource "aws_iam_role" "ec2_s3_access" {
  count = var.enable_ec2_instance && var.enable_s3 && var.create_ec2_s3_role ? 1 : 0
  name  = "${local.name_prefix}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Instance Profile para EC2
resource "aws_iam_instance_profile" "ec2_s3_access" {
  count = var.enable_ec2_instance && var.enable_s3 && var.create_ec2_s3_role ? 1 : 0
  name  = "${local.name_prefix}-ec2-s3-profile"
  role  = aws_iam_role.ec2_s3_access[0].name

  tags = local.common_tags
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

  # IAM instance profile para acceso a S3
  iam_instance_profile = var.enable_s3 && var.create_ec2_s3_role ? aws_iam_instance_profile.ec2_s3_access[0].name : ""

  tags = local.common_tags
}

# IAM Policy para acceso a S3 (debe crearse después del módulo S3)
resource "aws_iam_role_policy" "ec2_s3_access" {
  count = var.enable_ec2_instance && var.enable_s3 && var.create_ec2_s3_role ? 1 : 0
  name  = "${local.name_prefix}-ec2-s3-policy"
  role  = aws_iam_role.ec2_s3_access[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          var.enable_s3 ? module.s3[0].bucket_arn : "",
          var.enable_s3 ? "${module.s3[0].bucket_arn}/*" : ""
        ]
      }
    ]
  })
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

# Módulo de S3 para la aplicación
module "s3" {
  count  = var.enable_s3 ? 1 : 0
  source = "../../modules/s3"

  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : "${local.name_prefix}-app-data"

  enable_versioning            = var.s3_enable_versioning
  enable_lifecycle_transition  = var.s3_enable_lifecycle_transition
  transition_to_glacier_ir_days = var.s3_transition_to_glacier_ir_days
  transition_to_glacier_days   = var.s3_transition_to_glacier_days
  transition_to_deep_archive_days = var.s3_transition_to_deep_archive_days
  noncurrent_version_transition_to_glacier_ir_days = var.s3_noncurrent_version_transition_to_glacier_ir_days
  noncurrent_version_expiration_days = var.s3_noncurrent_version_expiration_days

  # Permitir acceso desde la instancia EC2 si tiene IAM role
  allowed_principal_arns = var.enable_ec2_instance && var.create_ec2_s3_role ? [aws_iam_role.ec2_s3_access[0].arn] : (var.ec2_iam_role_arn != "" ? [var.ec2_iam_role_arn] : [])

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

# ============================================================================
# Módulo de ALB (Application Load Balancer)
# ============================================================================
# NOTA: ALB es opcional. Solo se requiere si:
# 1. EC2 está en subnet privada Y CloudFront necesita acceso
# 2. Necesitas alta disponibilidad y load balancing
# 3. Si EC2 está en subnet pública, CloudFront puede apuntar directamente
module "alb" {
  count  = var.enable_alb && var.enable_cloudfront ? 1 : 0
  source = "../../modules/alb"

  name_prefix = local.name_prefix

  vpc_id     = module.network.vpc_id
  subnet_ids = [module.network.public_subnet_id] # ALB en subnet pública

  target_instance_ids = var.enable_ec2_instance ? [module.compute[0].instance_id] : []

  target_port     = 80
  target_protocol = "HTTP"

  certificate_arn = var.alb_certificate_arn != "" ? var.alb_certificate_arn : null

  health_check_path     = "/"
  health_check_protocol = "HTTP"
  health_check_matcher  = "200"

  enable_deletion_protection = false # Cambiar a true en producción

  tags = local.common_tags
}

# ============================================================================
# Módulo de WAF (Web Application Firewall)
# ============================================================================
# NOTA: WAF para CloudFront DEBE crearse en us-east-1
# El provider aws.us_east_1 está configurado en providers.tf
module "waf" {
  count  = var.enable_waf && var.enable_cloudfront ? 1 : 0
  source = "../../modules/waf"

  providers = {
    aws = aws.us_east_1 # CRÍTICO: WAF para CloudFront requiere us-east-1
  }

  name_prefix = local.name_prefix

  enable_rate_limiting = var.waf_enable_rate_limiting
  rate_limit          = var.waf_rate_limit

  tags = local.common_tags
}

# ============================================================================
# Módulo de CloudFront
# ============================================================================
# NOTA: CloudFront puede apuntar a:
# 1. ALB (si enable_alb=true) - Recomendado si EC2 está en subnet privada
# 2. EC2 directo (si enable_alb=false y EC2 está en subnet pública)
# 3. S3 bucket (si se especifica cloudfront_origin_s3_bucket)
module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "../../modules/cloudfront"

  name_prefix = local.name_prefix

  # Origen: ALB, S3, o EC2 directo (solo si está en subnet pública)
  # Prioridad: S3 > ALB > EC2 directo (solo si pública)
  origin_domain_name = var.cloudfront_origin_s3_bucket != "" ? "${var.cloudfront_origin_s3_bucket}.s3.${var.aws_region}.amazonaws.com" : (
    var.enable_alb && var.enable_cloudfront ? module.alb[0].alb_dns_name : (
      var.enable_ec2_instance && var.ec2_subnet_tier == "public" ? module.compute[0].instance_public_ip : ""
    )
  )
  
  origin_id = var.cloudfront_origin_s3_bucket != "" ? "s3-origin" : (
    var.enable_alb && var.enable_cloudfront ? "alb-origin" : (
      var.enable_ec2_instance && var.ec2_subnet_tier == "public" ? "ec2-origin" : "default-origin"
    )
  )

  # Protocolo según el origen
  origin_protocol_policy = var.cloudfront_origin_s3_bucket != "" ? "https-only" : (
    var.enable_alb ? "https-only" : "http-only"
  )
  origin_http_port  = 80
  origin_https_port = 443

  # WAF asociado (NO requiere ALB)
  waf_web_acl_id = var.enable_waf && var.enable_cloudfront ? module.waf[0].web_acl_arn : ""

  # Configuración de caché
  price_class         = var.cloudfront_price_class
  default_root_object = var.cloudfront_default_root_object
  enable_compression  = true

  # Viewer protocol policy: redirigir HTTP a HTTPS
  viewer_protocol_policy = "redirect-to-https"
  use_default_certificate = true # Usar certificado CloudFront por defecto

  tags = local.common_tags
}
