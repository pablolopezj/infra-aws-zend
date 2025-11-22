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

# Instancia Bastion Host
resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Security Group del bastion (permite SSH desde Internet)
  vpc_security_group_ids = [aws_security_group.bastion.id]

  # Key pair para SSH
  key_name = var.key_name != "" ? var.key_name : null

  # User data para hardening básico
  user_data = var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    # Actualizar sistema
    yum update -y
    
    # Instalar herramientas útiles
    yum install -y htop nano git
    
    # Configurar log de accesos
    echo "Bastion host initialized at $(date)" >> /var/log/bastion-init.log
  EOF

  # Root volume (mínimo 30GB requerido por el snapshot)
  root_block_device {
    volume_type = "gp3"
    volume_size = 30  # Mínimo 30GB requerido por el snapshot
    encrypted   = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-bastion-root"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-bastion"
      Role = "bastion"
      Tier = "public"
    }
  )
}

# Security Group para el Bastion
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-sg-bastion"
  description = "Security group for bastion host - allows SSH from Internet"
  vpc_id      = var.vpc_id

  # Permitir SSH desde CIDRs especificados
  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Permitir tráfico saliente a Internet
  egress {
    description = "Allow all outbound traffic to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir tráfico saliente a VPC (para acceder a instancias privadas)
  egress {
    description = "Allow outbound traffic to VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg-bastion"
      Role = "bastion"
    }
  )
}

