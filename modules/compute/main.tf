# Data source para obtener la AMI más reciente de Amazon Linux 2023 ARM64
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Usar AMI proporcionada o la más reciente de Amazon Linux 2023
locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
}

# Instancia EC2
resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  # Configuración de monitoreo
  monitoring = var.monitoring_enabled

  # Key pair (opcional)
  key_name = var.key_name != "" ? var.key_name : null

  # IAM instance profile (opcional, para acceso a S3 u otros servicios)
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # User data
  user_data = var.user_data != "" ? var.user_data : null

  # Tenencia: Instancias compartidas (default)
  # No se especifica tenancy, usa el default (shared)

  # Root volume (mínimo 30GB requerido por el snapshot)
  root_block_device {
    volume_type = "gp3"
    volume_size = 30  # Mínimo 30GB requerido por el snapshot
    encrypted   = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-root-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ec2"
    }
  )
}

# Volumen EBS adicional
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.this.availability_zone
  type              = var.ebs_volume_type
  size              = var.ebs_volume_size
  encrypted         = true

  # Configuración específica para gp3
  iops       = var.ebs_volume_type == "gp3" ? var.ebs_iops : null
  throughput = var.ebs_volume_type == "gp3" ? var.ebs_throughput : null

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ebs-data"
    }
  )
}

# Adjuntar volumen EBS a la instancia
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}

# IAM Role para Data Lifecycle Manager (para snapshots automáticos)
resource "aws_iam_role" "dlm_lifecycle_role" {
  count = var.enable_snapshots > 0 ? 1 : 0

  name = "${var.name_prefix}-dlm-lifecycle-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-dlm-lifecycle-role"
    }
  )
}

# IAM Policy para Data Lifecycle Manager
resource "aws_iam_role_policy" "dlm_lifecycle_policy" {
  count = var.enable_snapshots > 0 ? 1 : 0

  name = "${var.name_prefix}-dlm-lifecycle-policy"
  role = aws_iam_role.dlm_lifecycle_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*::snapshot/*"
      }
    ]
  })
}

# Data Lifecycle Manager Policy para snapshots automáticos
resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  count = var.enable_snapshots > 0 ? 1 : 0

  description        = "Automated EBS snapshot policy for ${var.name_prefix}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Name = "${var.name_prefix}-ebs-data"
    }

    schedule {
      name = "${var.name_prefix}-snapshot-schedule"

      # Para 1 snapshot al día: cada 24 horas
      # Para 2 snapshots al día: cada 12 horas
      # Para 4 snapshots al día: cada 6 horas
      create_rule {
        interval      = var.enable_snapshots == 1 ? 24 : 24 / var.enable_snapshots
        interval_unit = "HOURS"
        times         = ["00:00"]
      }

      retain_rule {
        count = var.snapshot_retention_days
      }

      copy_tags = true

      # Tags para los snapshots
      tags_to_add = merge(
        var.tags,
        {
          Name        = "${var.name_prefix}-snapshot"
          SnapshotType = "Automated"
        }
      )
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-dlm-policy"
    }
  )
}

