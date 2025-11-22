# Bucket S3 para la aplicación
resource "aws_s3_bucket" "app" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# Versionado del bucket
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Encriptación del bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política de ciclo de vida para transición a Glacier Instant Retrieval
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "transition-to-glacier-ir"
    status = var.enable_lifecycle_transition ? "Enabled" : "Disabled"

    # Filtro: aplicar a todos los objetos (sin prefijo)
    filter {
    }

    # Transición a Glacier Instant Retrieval después de X días
    transition {
      days          = var.transition_to_glacier_ir_days
      storage_class = "GLACIER_IR"
    }

    # Opcional: Transición a Glacier después de más tiempo
    dynamic "transition" {
      for_each = var.transition_to_glacier_days > 0 ? [1] : []
      content {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }

    # Opcional: Transición a Deep Archive después de aún más tiempo
    dynamic "transition" {
      for_each = var.transition_to_deep_archive_days > 0 ? [1] : []
      content {
        days          = var.transition_to_deep_archive_days
        storage_class = "DEEP_ARCHIVE"
      }
    }

    # Transición de versiones no actuales a Glacier IR (más económico)
    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_transition_to_glacier_ir_days > 0 ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_transition_to_glacier_ir_days
        storage_class   = "GLACIER_IR"
      }
    }

    # Expiración de versiones antiguas (después de transición)
    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration_days > 0 ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }

  # Regla para limpiar multipart uploads incompletos
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    # Filtro: aplicar a todos los objetos
    filter {
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Política del bucket para permitir acceso desde EC2 y/o CloudFront OAI
resource "aws_s3_bucket_policy" "app" {
  count  = length(var.allowed_principal_arns) > 0 || var.cloudfront_oai_iam_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Acceso desde EC2 (si se especifica)
      length(var.allowed_principal_arns) > 0 ? [
        {
          Sid    = "AllowAccessFromEC2"
          Effect = "Allow"
          Principal = {
            AWS = var.allowed_principal_arns
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = [
            aws_s3_bucket.app.arn,
            "${aws_s3_bucket.app.arn}/*"
          ]
        }
      ] : [],
      # Acceso desde CloudFront OAI (si se especifica)
      var.cloudfront_oai_iam_arn != "" ? [
        {
          Sid    = "AllowCloudFrontAccess"
          Effect = "Allow"
          Principal = {
            AWS = var.cloudfront_oai_iam_arn
          }
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.app.arn}/*"
        }
      ] : []
    )
  })
}

# Configuración de logging (opcional)
resource "aws_s3_bucket_logging" "app" {
  count  = var.enable_logging && var.logging_target_bucket != "" ? 1 : 0
  bucket = aws_s3_bucket.app.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# Configuración de CORS (si se necesita)
resource "aws_s3_bucket_cors_configuration" "app" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.app.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

