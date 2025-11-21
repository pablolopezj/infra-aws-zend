# Data source para obtener la versión de PostgreSQL
data "aws_rds_engine_version" "postgres" {
  engine = "postgres"
  # Si se especifica una versión, usarla; si no, usar la más reciente
  version = var.engine_version != "" ? var.engine_version : null
  preferred_versions = var.engine_version != "" ? [var.engine_version] : null
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-subnet-group"
    }
  )
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-sg-rds"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  # Permitir PostgreSQL (puerto 5432) desde Security Groups especificados
  ingress {
    description     = "PostgreSQL from allowed security groups"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  # Permitir PostgreSQL desde CIDR de la VPC (opcional, para debugging)
  ingress {
    description = "PostgreSQL from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg-rds"
    }
  )
}

# Parameter Group para optimizaciones de PostgreSQL
resource "aws_db_parameter_group" "this" {
  family = var.parameter_group_family
  name   = "${var.name_prefix}-db-params"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-params"
    }
  )
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-postgres"

  # Engine y versión
  engine         = "postgres"
  engine_version = data.aws_rds_engine_version.postgres.version

  # Tipo de instancia
  instance_class = var.instance_class

  # Almacenamiento
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true

  # Base de datos inicial
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  # Red y seguridad
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # Siempre en subnet privada

  # Availability Zone
  availability_zone = var.availability_zone

  # Backup y mantenimiento
  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.this.name

  # Performance Insights (opcional)
  performance_insights_enabled = var.enable_performance_insights

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Tags
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-postgres"
    }
  )
}

# IAM Role para Enhanced Monitoring (si está habilitado)
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

