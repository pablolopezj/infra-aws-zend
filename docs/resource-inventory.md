# Resource Inventory - infra-aws-zend

> **Estado**: Confirmado por código | **Región**: mx-central-1 (+ us-east-1 para WAF/ACM)

## Resumen por Servicio

| Servicio AWS | Cantidad de Recursos | Módulo Principal |
|-------------|---------------------|-----------------|
| VPC | 1 | network |
| Subnet | 3-4 | network + prod |
| Internet Gateway | 1 | network |
| NAT Gateway | 0-1 | network |
| Elastic IP | 0-1 | network |
| Route Table | 2 | network |
| Route | 2-3 | network |
| Security Group | 4-5 | network, alb, bastion, rds |
| Network ACL | 2 | network |
| VPC Endpoint | 0-2 | network |
| EC2 Instance | 1-2 | compute, bastion |
| EBS Volume | 1-2 | compute, bastion |
| Key Pair | 0-1 | keypair |
| IAM Role | 2-3 | compute, prod, rds |
| IAM Policy | 2-3 | prod, compute |
| IAM Instance Profile | 1 | prod |
| DLM Policy | 0-1 | compute |
| S3 Bucket | 1-2 | s3, state_backend |
| S3 Versioning | 1-2 | s3, state_backend |
| S3 Encryption | 1-2 | s3, state_backend |
| S3 Public Access Block | 1-2 | s3, state_backend |
| S3 Lifecycle | 1 | s3 |
| S3 Bucket Policy | 0-1 | s3 |
| ECR Repository | 0-1 | ecr |
| ECR Lifecycle Policy | 0-1 | ecr |
| ALB | 0-1 | alb |
| ALB Target Group | 0-1 | alb |
| ALB Listener | 1-2 | alb |
| ALB TG Attachment | 0-1 | alb |
| CloudFront Distribution | 0-1 | cloudfront |
| CloudFront OAI | 0-1 | cloudfront |
| WAFv2 Web ACL | 0-1 | waf |
| WAFv2 IP Set | 0-2 | waf |
| RDS Instance | 0-1 | rds |
| DB Subnet Group | 0-1 | rds |
| DB Parameter Group | 0-1 | rds |
| Secrets Manager Secret | 0-1 | prod |
| Secrets Manager Secret Version | 0-1 | prod |
| Random Password | 0-1 | prod |
| DynamoDB Table | 1 | state_backend |

---

## Inventario Detallado por Servicio

### VPC & Networking

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| VPC | `aws_vpc.this` | network | VPC principal 10.0.0.0/16 | **Alto** - Cambiar CIDR fuerza recreación total |
| Internet Gateway | `aws_internet_gateway.this` | network | Acceso a Internet | **Alto** - Eliminar rompe conectividad |
| Subnet Pública A | `aws_subnet.public` | network | 10.0.1.0/24 en mx-central-1a | **Alto** - Cambiar AZ/CIDR fuerza recreación |
| Subnet Pública B | `aws_subnet.public_b` | prod | 10.0.3.0/24 en mx-central-1b | **Alto** - Para ALB multi-AZ |
| Subnet Privada A | `aws_subnet.private` | network | 10.0.2.0/24 en mx-central-1a* | **Alto** - Cambiar AZ/CIDR fuerza recreación |
| Subnet Privada B | `aws_subnet.private_b` | network | 10.0.4.0/24 en mx-central-1c | **Alto** - Para RDS subnet group |
| Route Table Pública | `aws_route_table.public` | network | Rutas para subnet pública | Medio |
| Route Table Privada | `aws_route_table.private` | network | Rutas para subnet privada | Medio |
| Route IGW | `aws_route.public_internet_access` | network | 0.0.0.0/0 → IGW | Medio |
| Route NAT | `aws_route.private_nat_access` | network | 0.0.0.0/0 → NAT GW | Medio |
| NAT Gateway | `aws_nat_gateway.this` | network | Salida Internet subnet privada | **Alto** - Eliminar rompe salida EC2/RDS |
| Elastic IP | `aws_eip.nat` | network | IP pública para NAT Gateway | Bajo |

> *Nota: `private_subnet_az` default es `mx-central-1b` pero tfvars lo override a `mx-central-1a`

### Security Groups

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| SG Público | `aws_security_group.public` | network | HTTP/HTTPS desde Internet | **Alto** - Reglas amplias |
| SG Privado | `aws_security_group.private` | network | Todo tráfico VPC interno | **Alto** - Permite todo internamente |
| SG ALB | `aws_security_group.alb` | alb | HTTP/HTTPS desde Internet para ALB | Medio |
| SG Bastion | `aws_security_group.bastion` | bastion | SSH desde allowed_cidrs + VPC | **Alto** - Default 0.0.0.0/0 |
| SG RDS | `aws_security_group.rds` | rds | PostgreSQL desde SGs + VPC CIDR | Medio |
| SG Rule ALB→EC2 HTTP | `aws_security_group_rule.alb_to_ec2_http` | prod | HTTP desde ALB a EC2 privada | Bajo |
| SG Rule ALB→EC2 HTTPS | `aws_security_group_rule.alb_to_ec2_https` | prod | HTTPS desde ALB a EC2 privada | Bajo |

### Network ACLs

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| NACL Público | `aws_network_acl.public` | network | Control de acceso subnet pública | **Alto** - Permite SSH desde 0.0.0.0/0 |
| NACL Privado | `aws_network_acl.private` | network | Control de acceso subnet privada | **Alto** - Reglas muy amplias |
| NACL Assoc Público | `aws_network_acl_association.public` | network | Asociación subnet pública | Bajo |
| NACL Assoc Privado | `aws_network_acl_association.private` | network | Asociación subnet privada | Bajo |
| NACL Assoc Privado B | `aws_network_acl_association.private_b` | network | Asociación subnet privada B | Bajo |

### VPC Endpoints

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| S3 Endpoint | `aws_vpc_endpoint.s3` | network | Acceso S3 sin NAT | Bajo |
| DynamoDB Endpoint | `aws_vpc_endpoint.dynamodb` | network | Acceso DynamoDB sin NAT | Bajo |

### Compute (EC2)

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| EC2 Instance | `aws_instance.this` | compute | Servidor aplicación t4g.medium | **Alto** - Cambiar tipo fuerza recreación |
| EBS Volume | `aws_ebs_volume.data` | compute | 100GB gp3 datos | Medio |
| Volume Attachment | `aws_volume_attachment.data` | compute | Attach EBS a EC2 | Medio |
| Root Volume (inline) | - | compute | 30GB gp3 root encriptado | Bajo |

### IAM

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| IAM Role EC2-S3 | `aws_iam_role.ec2_s3_access` | prod | Role para EC2 acceso S3/SSM/Secrets | Medio |
| IAM Instance Profile | `aws_iam_instance_profile.ec2_s3_access` | prod | Profile para EC2 | Medio |
| IAM Policy S3 | `aws_iam_role_policy.ec2_s3_access` | prod | Policy S3 para EC2 | Medio |
| IAM Policy Secrets | `aws_iam_role_policy.ec2_secrets_access` | prod | Policy Secrets Manager para EC2 | Medio |
| IAM Attach ECR ReadOnly | `aws_iam_role_policy_attachment.ec2_ecr_readonly` | prod | ECR ReadOnly para EC2 | Bajo |
| IAM Attach SSM | `aws_iam_role_policy_attachment.ec2_ssm` | prod | SSM Managed Instance | Bajo |
| IAM Role DLM | `aws_iam_role.dlm_lifecycle_role` | compute | Role para DLM snapshots | Bajo |
| IAM Policy DLM | `aws_iam_role_policy.dlm_lifecycle_policy` | compute | Policy DLM (Resource *) | **Alto** - Demasiado permisiva |
| IAM Role RDS Monitoring | `aws_iam_role.rds_monitoring` | rds | Role para Enhanced Monitoring | Bajo |
| IAM Attach RDS Monitor | `aws_iam_role_policy_attachment.rds_monitoring` | rds | Policy Attachment RDS Monitoring | Bajo |

### Storage (S3)

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| S3 Bucket App | `aws_s3_bucket.app` | s3 | Bucket aplicación | **Alto** - Cambiar nombre fuerza recreación |
| S3 Versioning | `aws_s3_bucket_versioning.app` | s3 | Versionado del bucket | Bajo |
| S3 Encryption | `aws_s3_bucket_server_side_encryption_configuration.app` | s3 | Encriptación AES256 | Bajo |
| S3 Public Access Block | `aws_s3_bucket_public_access_block.app` | s3 | Bloqueo acceso público | Bajo |
| S3 Lifecycle | `aws_s3_bucket_lifecycle_configuration.app` | s3 | Transiciones Glacier IR/Deep Archive | Bajo |
| S3 Bucket Policy | `aws_s3_bucket_policy.app` | s3 | Policy para EC2 y CloudFront OAI | Medio |
| S3 Logging | `aws_s3_bucket_logging.app` | s3 | Access logs (condicional) | Bajo |
| S3 CORS | `aws_s3_bucket_cors_configuration.app` | s3 | CORS (condicional) | Bajo |
| S3 Bucket State | `aws_s3_bucket.state` | state_backend | Bucket Terraform state | **Crítico** |
| S3 Versioning State | `aws_s3_bucket_versioning.state` | state_backend | Versionado state | **Crítico** |
| S3 Encryption State | `aws_s3_bucket_server_side_encryption_configuration.state` | state_backend | Encriptación state | **Crítico** |
| S3 Public Access Block State | `aws_s3_bucket_public_access_block.state` | state_backend | Bloqueo público state | **Crítico** |

### ECR

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| ECR Repository | `aws_ecr_repository.app` | ecr | Repositorio Docker | **Alto** - Cambiar nombre fuerza recreación |
| ECR Lifecycle Policy | `aws_ecr_lifecycle_policy.app` | ecr | Limpieza imágenes antiguas | Bajo |
| ECR Repository Policy | `aws_ecr_repository_policy.app` | ecr | Policy de acceso (condicional) | Medio |

### Load Balancing (ALB)

| Servicio | Recurso Terraform | Módulo | Propuesto | Riesgo |
|----------|-------------------|--------|-----------|--------|
| ALB | `aws_lb.app` | alb | Application Load Balancer | **Alto** - Cambiar subnets fuerza recreación |
| ALB Target Group | `aws_lb_target_group.app` | alb | Target Group HTTP | Medio |
| ALB TG Attachment | `aws_lb_target_group_attachment.app` | alb | EC2 en TG | Bajo |
| ALB Listener HTTP | `aws_lb_listener.http` | alb | Listener puerto 80 | Medio |
| ALB Listener HTTPS | `aws_lb_listener.https` | alb | Listener puerto 443 (condicional) | Medio |

### CloudFront & CDN

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| CloudFront Distribution | `aws_cloudfront_distribution.app` | cloudfront | CDN para scorpionpys.mx | **Alto** - Deploy 5-15 min |
| CloudFront OAI | `aws_cloudfront_origin_access_identity.s3_oai` | cloudfront | OAI para acceso S3 | Medio |

### WAF

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| WAFv2 Web ACL | `aws_wafv2_web_acl.cloudfront` | waf | WAF para CloudFront (us-east-1) | Medio |
| WAFv2 IP Set (Allow) | `aws_wafv2_ip_set.allowed_ips` | waf | IPs permitidas (condicional) | Bajo |
| WAFv2 IP Set (Block) | `aws_wafv2_ip_set.blocked_ips` | waf | IPs bloqueadas (condicional) | Bajo |

### Database (RDS)

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| RDS Instance | `aws_db_instance.this` | rds | PostgreSQL 16.11 | **Crítico** - Datos persistentes |
| DB Subnet Group | `aws_db_subnet_group.this` | rds | Subnet group para RDS | **Alto** - Cambiar subnets fuerza recreación |
| DB Parameter Group | `aws_db_parameter_group.this` | rds | Parámetros PostgreSQL | Medio |
| RDS Security Group | `aws_security_group.rds` | rds | SG para PostgreSQL | Medio |

### Secrets Manager

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| SM Secret | `aws_secretsmanager_secret.rds_credentials` | prod | Secreto para credenciales RDS | **Crítico** |
| SM Secret Version | `aws_secretsmanager_secret_version.rds_credentials` | prod | Valores del secreto RDS | **Crítico** |
| Random Password | `random_password.rds_master` | prod | Password aleatorio RDS | **Crítico** |

### DynamoDB (State Backend)

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| DynamoDB Table | `aws_dynamodb_table.locks` | state_backend | Terraform state locking | **Crítico** |

### Route Tables & Associations

| Servicio | Recurso Terraform | Módulo | Propósito | Riesgo |
|----------|-------------------|--------|-----------|--------|
| RT Association Pub A | `aws_route_table_association.public_assoc` | network | Subnet pública A → RT pública | Bajo |
| RT Association Pub B | `aws_route_table_association.public_b_assoc` | prod | Subnet pública B → RT pública | Bajo |
| RT Association Priv A | `aws_route_table_association.private_assoc` | network | Subnet privada A → RT privada | Bajo |
| RT Association Priv B | `aws_route_table_association.private_b_assoc` | network | Subnet privada B → RT privada | Bajo |

---

## Recursos NO Gestionados por Terraform

Los siguientes recursos aparecen mencionados en el README pero **NO están implementados como recursos Terraform**:

| Recurso | Estado | Notas |
|---------|--------|-------|
| Route 53 Hosted Zone | **Documentado pero no verificado en código** | README lo lista como configurado |
| ACM Certificate | **ARN hardcodeado en tfvars** | No gestionado por Terraform |
| CloudWatch Alarms | No implementado | Listado como pendiente en README |
| CloudWatch Logs | No implementado | |
| Auto Scaling Groups | No implementado | Listado como pendiente en README |
| SSM Session Manager | **Configurado via IAM policy** | No hay recurso SSM explícito, solo IAM attachment |
| HTTPS end-to-end | No implementado | ALB escucha solo HTTP (sin certificado propio) |

---

## Recursos en us-east-1

| Recurso | Módulo | Propósito |
|---------|--------|-----------|
| WAFv2 Web ACL | waf | WAF para CloudFront (requiere us-east-1) |
| WAFv2 IP Sets | waf | IP sets del WAF |
| ACM Certificate | **Externo** | Certificado SSL para scorpionpys.mx (ARN en tfvars) |