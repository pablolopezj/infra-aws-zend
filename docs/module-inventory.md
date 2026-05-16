# Module Inventory - infra-aws-zend

> **Estado**: Confirmado por código | **Total módulos**: 11

## Resumen de Módulos

| Módulo | Ruta | Propósito | Habilitado por defecto |
|--------|------|-----------|----------------------|
| `state_backend` | `modules/state_backend/` | Backend remoto Terraform (S3 + DynamoDB) | Siempre (bootstrap) |
| `network` | `modules/network/` | VPC, subnets, routing, SG, NACL, endpoints | Siempre |
| `compute` | `modules/compute/` | EC2 + EBS + DLM snapshots | Condicional (`enable_ec2_instance`) |
| `keypair` | `modules/keypair/` | SSH key pair | Condicional (`create_key_pair`) |
| `bastion` | `modules/bastion/` | Bastion host en subnet pública | Condicional (`enable_bastion`) |
| `s3` | `modules/s3/` | Bucket S3 para aplicación | Condicional (`enable_s3`) |
| `ecr` | `modules/ecr/` | Repositorio Docker ECR | Condicional (`enable_ecr`) |
| `alb` | `modules/alb/` | Application Load Balancer | Condicional (`enable_alb && enable_cloudfront`) |
| `cloudfront` | `modules/cloudfront/` | CDN + SSL | Condicional (`enable_cloudfront`) |
| `waf` | `modules/waf/` | Web Application Firewall | Condicional (`enable_waf && enable_cloudfront`) |
| `rds` | `modules/rds/` | PostgreSQL + Parameter Group + SG | Condicional (`enable_rds`) |

---

## state_backend

**Propósito**: Crea el backend remoto para Terraform (S3 para state + DynamoDB para locks).

**Invocado desde**: `envs/bootstrap/main.tf`

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `bucket_name` | string | - | Sí |
| `dynamodb_table_name` | string | - | Sí |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `bucket_id` | Nombre del bucket S3 (`zend-terraform-state`) |
| `dynamodb_table_id` | Nombre de la tabla DynamoDB (`zend-terraform-locks`) |

### Recursos creados

| Recurso | Tipo | Descripción |
|---------|------|-------------|
| `aws_s3_bucket.state` | S3 Bucket | Almacena estado Terraform |
| `aws_s3_bucket_versioning.state` | S3 Versioning | Versionado habilitado |
| `aws_s3_bucket_server_side_encryption_configuration.state` | S3 Encryption | AES256 |
| `aws_s3_bucket_public_access_block.state` | S3 Public Access | Todo bloqueado |
| `aws_dynamodb_table.locks` | DynamoDB Table | Lock con hash key `LockID`, PAY_PER_REQUEST |

### Dependencias
- Ninguna (módulo raíz, sin dependencias)

### Riesgos al modificar
- **CRÍTICO**: Modificar el nombre del bucket o tabla DynamoDB rompe el backend de state. Nunca cambiar sin migración.
- **CRÍTICO**: Eliminar `public_access_block` expondría el state de Terraform públicamente.

---

## network

**Propósito**: Crea toda la infraestructura de red: VPC, subnets, route tables, IGW, NAT Gateway, Security Groups, NACLs y VPC Endpoints.

**Invocado desde**: `envs/prod/main.tf`

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `vpc_cidr` | string | - | Sí |
| `public_subnet_cidr` | string | - | Sí |
| `public_subnet_az` | string | - | Sí |
| `private_subnet_cidr` | string | - | Sí |
| `private_subnet_az` | string | - | Sí |
| `private_subnet_b_cidr` | string | `""` | No |
| `private_subnet_b_az` | string | `""` | No |
| `name_prefix` | string | - | Sí |
| `tags` | map(string) | `{}` | No |
| `enable_vpc_endpoints` | bool | `true` | No |
| `enable_nat_gateway` | bool | `false` | No |
| `allowed_public_ingress_cidrs` | list(string) | `["0.0.0.0/0"]` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `vpc_id` | ID de la VPC |
| `public_subnet_id` | ID de la subnet pública |
| `private_subnet_id` | ID de la subnet privada A |
| `private_subnet_b_id` | ID de la subnet privada B (null si no existe) |
| `public_security_group_id` | ID del SG público |
| `private_security_group_id` | ID del SG privado |
| `internet_gateway_id` | ID del Internet Gateway |
| `nat_gateway_id` | ID del NAT Gateway (null si deshabilitado) |
| `s3_vpc_endpoint_id` | ID del VPC Endpoint S3 |
| `dynamodb_vpc_endpoint_id` | ID del VPC Endpoint DynamoDB |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_vpc.this` | VPC | Siempre |
| `aws_internet_gateway.this` | Internet Gateway | Siempre |
| `aws_subnet.public` | Subnet Pública A | Siempre |
| `aws_subnet.private` | Subnet Privada A | Siempre |
| `aws_subnet.private_b` | Subnet Privada B | Si `private_subnet_b_cidr != ""` |
| `aws_route_table.public` | Route Table Pública | Siempre |
| `aws_route_table.private` | Route Table Privada | Siempre |
| `aws_route.public_internet_access` | Route 0.0.0.0/0 → IGW | Siempre |
| `aws_route_table_association.public_assoc` | Subnet → RT Pública | Siempre |
| `aws_route_table_association.private_assoc` | Subnet → RT Privada | Siempre |
| `aws_route_table_association.private_b_assoc` | Subnet B → RT Privada | Condicional |
| `aws_eip.nat` | Elastic IP para NAT | Si `enable_nat_gateway` |
| `aws_nat_gateway.this` | NAT Gateway | Si `enable_nat_gateway` |
| `aws_route.private_nat_access` | Route 0.0.0.0/0 → NAT | Si `enable_nat_gateway` |
| `aws_security_group.public` | SG Público (80, 443) | Siempre |
| `aws_security_group.private` | SG Privado (todo VPC) | Siempre |
| `aws_network_acl.public` | NACL Público | Siempre |
| `aws_network_acl.private` | NACL Privado | Siempre |
| `aws_network_acl_association.public` | Asociación NACL Público | Siempre |
| `aws_network_acl_association.private` | Asociación NACL Privado | Siempre |
| `aws_network_acl_association.private_b` | Asociación NACL Privado B | Condicional |
| `aws_vpc_endpoint.s3` | VPC Endpoint S3 | Si `enable_vpc_endpoints` |
| `aws_vpc_endpoint.dynamodb` | VPC Endpoint DynamoDB | Si `enable_vpc_endpoints` |

### Dependencias
- Sin dependencias de otros módulos (módulo base)

### Riesgos al modificar
- **CRÍTICO**: Cambiar CIDR de VPC o subnets fuerza recreación de TODA la infraestructura.
- **ALTO**: Cambiar AZ de una subnet fuerza recreación de EC2, RDS, ALB que dependen de ella.
- **ALTO**: Deshabilitar NAT Gateway rompe salida a internet de subnets privadas.
- **MEDIO**: Modificar NACLs puede interrumpir conectividad.
- **BAJO**: Cambiar tags no interrumpe servicio.

---

## compute

**Propósito**: Crea instancia EC2 con Amazon Linux 2023 ARM64, volumen EBS adicional y política de snapshots automáticos.

**Invocado desde**: `envs/prod/main.tf`

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `subnet_id` | string | - | Sí |
| `security_group_ids` | list(string) | - | Sí |
| `instance_type` | string | `t4g.medium` | No |
| `ami_id` | string | `""` (auto) | No |
| `key_name` | string | `""` | No |
| `monitoring_enabled` | bool | `false` | No |
| `ebs_volume_size` | number | `100` | No |
| `ebs_volume_type` | string | `gp3` | No |
| `ebs_iops` | number | `3000` | No |
| `ebs_throughput` | number | `125` | No |
| `enable_snapshots` | number | `1` | No |
| `snapshot_retention_days` | number | `7` | No |
| `iam_instance_profile` | string | `""` | No |
| `user_data` | string | `""` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `instance_id` | ID de la instancia EC2 |
| `instance_arn` | ARN de la instancia |
| `instance_public_ip` | IP pública (vacía si en subnet privada) |
| `instance_private_ip` | IP privada |
| `ebs_volume_id` | ID del volumen EBS adicional |
| `dlm_lifecycle_policy_id` | ID de la política DLM |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_instance.this` | EC2 Instance | Siempre |
| `aws_ebs_volume.data` | EBS Volume | Siempre |
| `aws_volume_attachment.data` | Volume Attachment | Siempre |
| `aws_iam_role.dlm_lifecycle_role` | IAM Role | Si `enable_snapshots > 0` |
| `aws_iam_role_policy.dlm_lifecycle_policy` | IAM Policy | Si `enable_snapshots > 0` |
| `aws_dlm_lifecycle_policy.ebs_snapshots` | DLM Policy | Si `enable_snapshots > 0` |

### Dependencias
- `network` (subnet_id, security_group_ids)
- `keypair` (key_name) - opcional

### Riesgos al modificar
- **ALTO**: Cambiar `instance_type` fuerza recreación de la instancia.
- **ALTO**: Cambiar `ami_id` fuerza recreación.
- **MEDIO**: Cambiar `subnet_id` fuerza recreación.
- **BAJO**: Cambiar `ebs_volume_size` no fuerza recreación (expansión en vivo).

---

## keypair

**Propósito**: Crea un SSH key pair en AWS.

**Invocado desde**: `envs/prod/main.tf`

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `key_name` | string | - | Sí |
| `public_key` | string | - | Sí (sensitive) |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `key_name` | Nombre del key pair |
| `key_pair_id` | ID del key pair |

### Recursos creados

| Recurso | Tipo |
|---------|------|
| `aws_key_pair.this` | Key Pair |

### Dependencias
- Ninguna

### Riesgos al modificar
- **ALTO**: Cambiar `key_name` o `public_key` fuerza recreación del key pair, lo que puede impedir SSH si no se actualiza la instancia.

---

## bastion

**Propósito**: Crea un bastion host en subnet pública para acceso SSH a instancias privadas.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_bastion`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `vpc_id` | string | - | Sí |
| `subnet_id` | string | - | Sí |
| `vpc_cidr` | string | - | Sí |
| `instance_type` | string | `t4g.micro` | No |
| `key_name` | string | `""` | No |
| `allowed_ssh_cidrs` | list(string) | `["0.0.0.0/0"]` | No |
| `tags` | map(string) | `{}` | No |

### Recursos creados

| Recurso | Tipo |
|---------|------|
| `aws_instance.this` | EC2 Instance (Amazon Linux 2023 ARM64) |
| `aws_security_group.bastion` | Security Group (SSH + VPC) |

### Dependencias
- `network` (vpc_id, subnet_id, vpc_cidr)
- `keypair` (key_name) - opcional

### Riesgos al modificar
- **ALTO**: Default `allowed_ssh_cidrs = ["0.0.0.0/0"]` permite SSH desde cualquier IP.
- **MEDIO**: Cambiar instance_type fuerza recreación.

---

## s3

**Propósito**: Crea bucket S3 para aplicación con encryption, lifecycle, public access block y bucket policy.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_s3`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `bucket_name` | string | - | Sí |
| `enable_versioning` | bool | `true` | No |
| `enable_lifecycle_transition` | bool | `true` | No |
| `transition_to_glacier_ir_days` | number | `30` | No |
| `allowed_principal_arns` | list(string) | `[]` | No |
| `cloudfront_oai_iam_arn` | string | `""` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `bucket_id` | Nombre del bucket |
| `bucket_arn` | ARN del bucket |
| `bucket_domain_name` | Domain name del bucket |
| `bucket_regional_domain_name` | Regional domain name del bucket |
| `bucket_hosted_zone_id` | Route 53 Hosted Zone ID |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_s3_bucket.app` | S3 Bucket | Siempre |
| `aws_s3_bucket_versioning.app` | Versioning | Siempre |
| `aws_s3_bucket_server_side_encryption_configuration.app` | Encryption | Siempre |
| `aws_s3_bucket_public_access_block.app` | Public Access Block | Siempre |
| `aws_s3_bucket_lifecycle_configuration.app` | Lifecycle | Siempre |
| `aws_s3_bucket_policy.app` | Bucket Policy | Si hay principals u OAI |
| `aws_s3_bucket_logging.app` | Access Logging | Si enable_logging |
| `aws_s3_bucket_cors_configuration.app` | CORS | Si hay cors_rules |

### Dependencias
- CloudFront OAI (para bucket policy)

### Riesgos al modificar
- **ALTO**: Cambiar `bucket_name` fuerza recreación del bucket (pérdida de datos).
- **MEDIO**: Deshabilitar `public_access_block` exppondría el bucket.
- **BAJO**: Cambiar lifecycle rules no interrumpe servicio.

---

## ecr

**Propósito**: Crea repositorio ECR para imágenes Docker con scanning y lifecycle policy.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_ecr`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `repository_name` | string | - | Sí |
| `image_tag_mutability` | string | `MUTABLE` | No |
| `scan_on_push` | bool | `true` | No |
| `encryption_type` | string | `AES256` | No |
| `enable_lifecycle_policy` | bool | `true` | No |
| `max_image_count` | number | `10` | No |
| `max_image_age_days` | number | `30` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `repository_id` | ID del repositorio |
| `repository_arn` | ARN del repositorio |
| `repository_name` | Nombre del repositorio |
| `repository_url` | URL del repositorio |
| `registry_id` | ID del registro |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_ecr_repository.app` | ECR Repository | Siempre |
| `aws_ecr_lifecycle_policy.app` | Lifecycle Policy | Si `enable_lifecycle_policy` |
| `aws_ecr_repository_policy.app` | Repository Policy | Si `repository_policy != ""` |

### Dependencias
- Ninguna

### Riesgos al modificar
- **ALTO**: Cambiar `repository_name` fuerza recreación.
- **MEDIO**: Cambiar `image_tag_mutability` a `IMMUTABLE` previene sobreescribir tags existentes.

---

## alb

**Propósito**: Crea Application Load Balancer con security group, target group y listeners HTTP/HTTPS.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_alb && enable_cloudfront`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `vpc_id` | string | - | Sí |
| `subnet_ids` | list(string) | - | Sí |
| `target_instance_ids` | list(string) | `[]` | No |
| `target_port` | number | `80` | No |
| `certificate_arn` | string | `""` | No |
| `enable_deletion_protection` | bool | `false` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `alb_id` | ALB ID |
| `alb_arn` | ALB ARN |
| `alb_dns_name` | DNS name del ALB |
| `target_group_arn` | ARN del target group |
| `security_group_id` | SG ID del ALB |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_lb.app` | ALB | Siempre |
| `aws_security_group.alb` | Security Group | Siempre |
| `aws_lb_target_group.app` | Target Group | Siempre |
| `aws_lb_target_group_attachment.app` | TG Attachment | Por cada instancia |
| `aws_lb_listener.http` | HTTP Listener | Siempre |
| `aws_lb_listener.https` | HTTPS Listener | Si `certificate_arn != ""` |

### Dependencias
- `network` (vpc_id, subnet_ids)
- `compute` (target_instance_ids)

### Riesgos al modificar
- **ALTO**: Cambiar `subnet_ids` fuerza recreación del ALB.
- **ALTO**: Cambiar de HTTP a HTTPS (agregar certificado) requiere recreación del listener.
- **MEDIO**: `enable_deletion_protection = false` en producción es riesgoso.

---

## cloudfront

**Propósito**: Crea distribución CloudFront con soporte para custom domain, SSL/TLS, WAF y S3 OAI.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_cloudfront`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `origin_domain_name` | string | - | Sí |
| `origin_type` | string | `custom` | No |
| `waf_web_acl_id` | string | `""` | No |
| `price_class` | string | `PriceClass_100` | No |
| `use_default_certificate` | bool | `true` | No |
| `acm_certificate_arn` | string | `""` | No |
| `aliases` | list(string) | `[]` | No |
| `viewer_protocol_policy` | string | `redirect-to-https` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `distribution_id` | ID de la distribución |
| `distribution_arn` | ARN de la distribución |
| `distribution_domain_name` | Domain name de CloudFront |
| `distribution_hosted_zone_id` | Route 53 Hosted Zone ID |
| `origin_access_identity_iam_arn` | IAM ARN del OAI (para S3) |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_cloudfront_origin_access_identity.s3_oai` | OAI | Si `origin_type == "s3"` y no hay OAI existente |
| `aws_cloudfront_distribution.app` | CloudFront Distribution | Siempre |

### Dependencias
- `alb` (origin_domain_name) - si `enable_alb`
- `s3` (origin_domain_name) - si `cloudfront_origin_s3_bucket != ""`
- `waf` (web_acl_arn)
- ACM Certificate (externo, no gestionado por Terraform)

### Riesgos al modificar
- **ALTO**: Cambiar `origin_domain_name` o `origin_type` fuerza recreación de la distribución.
- **ALTO**: Cambiar `aliases` puede requerir validación DNS.
- **MEDIO**: Cambiar `price_class` afecta latencia/costo sin interrupción.
- **BAJO**: CloudFront deployments tardan 5-15 minutos.

---

## waf

**Propósito**: Crea WAFv2 Web ACL para CloudFront con reglas administradas de AWS y rate limiting opcional.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_waf && enable_cloudfront`)

**Región**: us-east-1 (requisito de AWS para CloudFront scope)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `enable_cloudwatch_metrics` | bool | `true` | No |
| `enable_sampled_requests` | bool | `true` | No |
| `enable_rate_limiting` | bool | `false` | No |
| `rate_limit` | number | `2000` | No |
| `allowed_ip_cidrs` | list(string) | `[]` | No |
| `blocked_ip_cidrs` | list(string) | `[]` | No |
| `custom_rules` | list(object) | `[]` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `web_acl_id` | ID del Web ACL |
| `web_acl_arn` | ARN del Web ACL |
| `web_acl_name` | Nombre del Web ACL |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_wafv2_web_acl.cloudfront` | WAFv2 Web ACL | Siempre |
| `aws_wafv2_ip_set.allowed_ips` | IP Set (allow) | Si `len(allowed_ip_cidrs) > 0` |
| `aws_wafv2_ip_set.blocked_ips` | IP Set (block) | Si `len(blocked_ip_cidrs) > 0` |

### Reglas WAF incluidas

| Regla | Prioridad | Tipo |
|-------|-----------|------|
| AWSManagedRulesCommonRuleSet | 1 | Managed Rule Group |
| AWSManagedRulesKnownBadInputsRuleSet | 2 | Managed Rule Group |
| RateLimitRule | 3 | Rate-based (condicional) |

### Dependencias
- Ninguna (pero DEBE crearse en us-east-1)

### Riesgos al modificar
- **ALTO**: Cambiar scope de `CLOUDFRONT` a `REGIONAL` rompe la asociación con CloudFront.
- **MEDIO**: Agregar reglas puede bloquear tráfico legítimo.
- **BAJO**: Cambiar rate_limit no interrumpe servicio.

---

## rds

**Propósito**: Crea instancia RDS PostgreSQL con subnet group, security group, parameter group y role de monitoring.

**Invocado desde**: `envs/prod/main.tf` (condicional: `enable_rds`)

### Inputs principales

| Variable | Tipo | Default | Requerido |
|----------|------|---------|-----------|
| `name_prefix` | string | - | Sí |
| `vpc_id` | string | - | Sí |
| `vpc_cidr` | string | - | Sí |
| `subnet_ids` | list(string) | - | Sí |
| `availability_zone` | string | - | Sí |
| `instance_class` | string | `db.t4g.medium` | No |
| `allocated_storage` | number | `200` | No |
| `storage_type` | string | `gp3` | No |
| `database_name` | string | `zenddb` | No |
| `master_username` | string | `postgres` | No |
| `master_password` | string | - | Sí (sensitive) |
| `engine_version` | string | `16` | No |
| `parameter_group_family` | string | `postgres16` | No |
| `timezone` | string | `America/Mexico_City` | No |
| `backup_retention_days` | number | `7` | No |
| `skip_final_snapshot` | bool | `false` | No |
| `tags` | map(string) | `{}` | No |

### Outputs principales

| Output | Descripción |
|--------|-------------|
| `db_instance_id` | Identificador de la instancia |
| `db_instance_endpoint` | Endpoint (hostname:port) |
| `db_instance_address` | Hostname |
| `db_instance_port` | Puerto |
| `db_instance_name` | Nombre de la base de datos |
| `db_instance_username` | Username (sensitive) |
| `db_security_group_id` | ID del Security Group |

### Recursos creados

| Recurso | Tipo | Condicional |
|---------|------|-------------|
| `aws_db_subnet_group.this` | DB Subnet Group | Siempre |
| `aws_security_group.rds` | Security Group | Siempre |
| `aws_db_parameter_group.this` | Parameter Group | Siempre |
| `aws_db_instance.this` | RDS Instance | Siempre |
| `aws_iam_role.rds_monitoring` | IAM Role | Si `monitoring_interval > 0` |
| `aws_iam_role_policy_attachment.rds_monitoring` | IAM Policy Attachment | Si `monitoring_interval > 0` |

### Dependencias
- `network` (vpc_id, subnet_ids)
- Secrets Manager (credenciales - creado en envs/prod)

### Riesgos al modificar
- **CRÍTICO**: Cambiar `master_password` requiere reinicio de RDS.
- **ALTO**: Cambiar `instance_class` o `allocated_storage` puede causar downtime.
- **ALTO**: Cambiar `engine_version` puede forzar upgrade mayor.
- **CRÍTICO**: `skip_final_snapshot = false` (default) significa que `terraform destroy` tomará snapshot final (esperar tiempo).
- **MEDIO**: Cambiar `storage_type` fuerza recreación.