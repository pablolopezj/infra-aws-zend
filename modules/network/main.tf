resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# Subred pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-public-a"
      Tier = "public"
    }
  )
}

# Subred privada
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidr
  availability_zone = var.private_subnet_az

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-private-a"
      Tier = "private"
    }
  )
}

# Tabla de ruteo pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rt-public"
    }
  )
}

# Ruta por defecto hacia Internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Asociar tabla de ruteo pública a la subred pública
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Tabla de ruteo privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rt-private"
    }
  )
}

# Asociar tabla de ruteo privada a la subred privada
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# Security Groups
# ============================================================================

# Security Group para subred pública
resource "aws_security_group" "public" {
  name        = "${var.name_prefix}-sg-public"
  description = "Security group for public subnet resources"
  vpc_id      = aws_vpc.this.id

  # Permitir tráfico HTTP desde cualquier lugar
  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_public_ingress_cidrs
  }

  # Permitir tráfico HTTPS desde cualquier lugar
  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_public_ingress_cidrs
  }

  # Permitir tráfico saliente a cualquier lugar
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
      Name = "${var.name_prefix}-sg-public"
      Tier = "public"
    }
  )
}

# Security Group para subred privada
resource "aws_security_group" "private" {
  name        = "${var.name_prefix}-sg-private"
  description = "Security group for private subnet resources"
  vpc_id      = aws_vpc.this.id

  # Permitir tráfico desde la subred pública
  ingress {
    description     = "Allow traffic from public subnet"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  # Permitir SSH desde cualquier instancia en subnet pública (incluye bastion)
  ingress {
    description = "Allow SSH from public subnet (bastion access)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  # Permitir tráfico interno dentro de la VPC
  ingress {
    description = "Allow internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Permitir tráfico saliente a cualquier lugar
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
      Name = "${var.name_prefix}-sg-private"
      Tier = "private"
    }
  )
}

# ============================================================================
# Network ACLs
# ============================================================================

# Network ACL para subred pública
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  # Permitir tráfico HTTP entrante
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Permitir tráfico HTTPS entrante
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Permitir tráfico SSH entrante (para bastion host)
  ingress {
    rule_no    = 115
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Permitir tráfico entrante desde VPC
  ingress {
    rule_no    = 120
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = var.vpc_cidr
    action     = "allow"
  }

  # Permitir tráfico saliente
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Permitir tráfico saliente a VPC
  egress {
    rule_no    = 110
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = var.vpc_cidr
    action     = "allow"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nacl-public"
      Tier = "public"
    }
  )
}

# Asociar Network ACL a subred pública
resource "aws_network_acl_association" "public" {
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public.id
}

# Network ACL para subred privada
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id

  # Permitir tráfico entrante desde VPC
  ingress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = var.vpc_cidr
    action     = "allow"
  }

  # Permitir tráfico saliente a VPC
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = var.vpc_cidr
    action     = "allow"
  }

  # Permitir tráfico saliente a Internet (para NAT Gateway futuro)
  egress {
    rule_no    = 110
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nacl-private"
      Tier = "private"
    }
  )
}

# Asociar Network ACL a subred privada
resource "aws_network_acl_association" "private" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private.id
}

# ============================================================================
# VPC Endpoints (para minimizar tráfico externo)
# ============================================================================

# VPC Endpoint para S3 (Gateway Endpoint - gratuito)
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc-endpoint-s3"
    }
  )
}

# VPC Endpoint para DynamoDB (Gateway Endpoint - gratuito)
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc-endpoint-dynamodb"
    }
  )
}

# Data source para obtener la región actual
data "aws_region" "current" {}
