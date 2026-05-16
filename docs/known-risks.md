# Known Risks - infra-aws-zend

> **Última actualización**: 2026-05-16 | **Clasificación**: Por categoría

## Riesgos Técnicos

### RISK-TECH-001: Cambios de CIDR o AZ fuerzan recreación total

| Atributo | Valor |
|----------|-------|
| **Severidad** | CRÍTICO |
| **Módulo** | `modules/network` |
| **Descripción** | Cambiar `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, o las AZs de las subnets fuerza la recreación de TODA la infraestructura dependiente |
| **Impacto** | EC2, RDS, ALB, y todos los recursos en esas subnets serían destruidos y recreados |
| **Mitigación** | Definir los CIDRs y AZs correctamente desde el inicio y NO cambiarlos. Las variables tienen validación para prevenir errores. |

### RISK-TECH-002: Route 53 no gestionado por Terraform

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | Ninguno (no implementado) |
| **Descripción** | Route 53 Hosted Zone y records no están gestionados por Terraform, a pesar de estar documentado como "configurado" en el README |
| **Impacto** | Si los registros DNS se modifican accidentalmente, no hay manera de restaurarlos automáticamente |
| **Mitigación** | Crear módulo de Route 53 y gestionar DNS como código. Documentar la configuración DNS manual actual. |

### RISK-TECH-003: ACM Certificate no gestionado por Terraform

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | Ninguno (ARN hardcodeado) |
| **Descripción** | El certificado ACM está referenciado por ARN hardcodeado en `terraform.tfvars` pero no fue creado ni se gestiona por Terraform |
| **Impacto** | Si el certificado expira o es eliminado, CloudFront falla. La renovación automática depende de AWS |
| **Mitigación** | (1) Implementar módulo ACM en Terraform, (2) Configurar alertas de expiración en AWS, (3) Verificar renewal automático |

### RISK-TECH-004: ALB solo se crea con CloudFront habilitado

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` |
| **Descripción** | El ALB solo se crea cuando `enable_alb && enable_cloudfront` son ambos true. No se puede tener ALB sin CloudFront |
| **Impacto** | Si se deshabilita CloudFront, el ALB también se destruye, causando downtime |
| **Mitigación** | Separar las condiciones `enable_alb` de `enable_cloudfront` si se necesita ALB independiente |

### RISK-TECH-005: Contraseña RDS generada por `random_password`

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` |
| **Descripción** | La contraseña RDS se genera con `random_password` y se almacena en Secrets Manager. Si el recurso `random_password` se recrea, la contraseña cambiará y RDS se actualizará |
| **Impacto** | Cambio de contraseña causa reinicio de RDS (disruptivo) |
| **Mitigación** | Agregar `keepers` al `random_password` o usar `lifecycle { ignore_changes = [master_password] }` en el recurso RDS |

### RISK-TECH-006: WAF creado en us-east-1

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/waf` |
| **Descripción** | El WAF se crea en us-east-1 usando provider alias. Esto funciona correctamente pero puede causar confusión |
| **Impacto** | Si se elimina el provider alias accidentalmente, Terraform intentará crear el WAF en mx-central-1, lo cual falla |
| **Mitigación** | Documentar claramente el requisito. El módulo ya tiene un `versions.tf` que especifica el provider |

### RISK-TECH-007: Dependencia circular potencial S3 ↔ CloudFront

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` |
| **Descripción** | El bucket policy de S3 depende del OAI de CloudFront, y CloudFront depende del bucket S3. Se usa `try()` para manejar el caso donde CloudFront aún no existe |
| **Impacto** | En el primer apply, el OAI puede no existir todavía cuando se crea el bucket policy |
| **Mitigación** | El uso de `try()` ya es una mitigación. Aplicar dos veces si es necesario. |

---

## Riesgos de Seguridad

### RISK-SEC-001: Contraseña RDS en tfvars (texto plano)

| Atributo | Valor |
|----------|-------|
| **Severidad** | CRÍTICO |
| **Módulo** | `envs/prod/terraform.tfvars` |
| **Descripción** | La contraseña `rds_master_password` está hardcodeada en texto plano en el archivo tfvars |
| **Impacto** | Cualquier persona con acceso al repositorio puede ver la contraseña de producción |
| **Mitigación** | (1) Eliminar la contraseña del tfvars, (2) Usar Variables de entorno `TF_VAR_rds_master_password`, (3) Agregar `*.tfvars` al `.gitignore` (ya está), (4) Rotar la contraseña |

### RISK-SEC-002: NACLs permisivos

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network` |
| **Descripción** | NACLs permiten ICMP, SSH (22) desde 0.0.0.0/0, y puertos efímeros amplios |
| **Impacto** | Reducción de la postura de seguridad, permite escaneo de puertos y reconocimiento |
| **Mitigación** | Restringir reglas NACL a IPs específicas y puertos mínimos necesarios |

### RISK-SEC-003: Bastion SSH abierto por defecto

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/bastion` |
| **Descripción** | El bastion permite SSH desde `0.0.0.0/0` por defecto |
| **Impacto** | Si `enable_bastion=true` sin override, el bastion es accesible desde cualquier IP |
| **Mitigación** | Cambiar default a `[]` y requerir IPs explícitas. Actualmente el bastion está deshabilitado (`enable_bastion=false`) |

### RISK-SEC-004: SG Privado permite todo el tráfico VPC

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network` |
| **Descripción** | El SG privado (`aws_security_group.private`) permite todo el tráfico (`-1` protocol) desde el CIDR completo de la VPC |
| **Impacto** | Cualquier recurso en la VPC puede acceder a cualquier puerto de instancias privadas |
| **Mitigación** | Reemplazar con reglas específicas por puerto y SG |

### RISK-SEC-005: Tráfico CloudFront → ALB sin cifrar

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` + `modules/cloudfront` |
| **Descripción** | El tráfico entre CloudFront y el ALB es HTTP (puerto 80) sin cifrar. Solo el tráfico usuario → CloudFront está cifrado |
| **Impacto** | El tráfico interno entre CloudFront y ALB atraviesa la red de AWS sin cifrar |
| **Mitigación** | Configurar certificado ACM en el ALB y cambiar `origin_protocol_policy` a `https-only` |

---

## Riesgos de Costos

### RISK-COST-001: NAT Gateway siempre activo

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network` |
| **Descripción** | NAT Gateway cobra $0.045/hr (~$32/mes) independientemente del uso |
| **Impacto** | Costo fijo mensual significativo |
| **Mitigación** | (1) Agregar VPC Endpoints para SSM/ECR para reducir data processing, (2) Considerar eliminar NAT si todo el outbound usa VPC Endpoints |

### RISK-COST-002: RDS con almacenamiento sobreaprovisionado

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/rds` |
| **Descripción** | RDS tiene 200GB gp3 por defecto. Si la base de datos usa menos, se paga por almacenamiento no utilizado |
| **Impacto** | ~$8/mes adicionales si se usa solo 100GB |
| **Mitigación** | Ajustar `allocated_storage` al uso real. gp3 permite reducir storage en vivo (con límites) |

### RISK-COST-003: Sin Reserved Instances ni Savings Plans

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | N/A |
| **Descripción** | Todos los recursos están bajo demanda |
| **Impacto** | Ahorro potencial de 30-50% con Reserved Instances |
| **Mitigación** | Evaluar Reserved Instances para EC2 y RDS después de 1 mes de uso estable |

---

## Riesgos Operacionales

### RISK-OPS-001: No hay CloudWatch Alarms

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | No implementado |
| **Descripción** | No hay alarmas de CloudWatch para monitorear EC2, RDS, ALB, o CloudFront |
| **Impacto** | No hay alertas automáticas para problemas de infraestructura |
| **Mitigación** | Implementar módulo de CloudWatch Alarms y SNS notifications |

### RISK-OPS-002: No hay Auto Scaling

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | No implementado |
| **Descripción** | EC2 es una instancia única sin auto scaling |
| **Impacto** | Si la instancia falla, la aplicación queda inaccesible hasta intervención manual |
| **Mitigación** | Implementar ASG con ALB health checks |

### RISK-OPS-003: RDS single-AZ

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/rds` |
| **Descripción** | RDS está desplegado en una sola AZ (`availability_zone`) |
| **Impacto** | Si la AZ falla, la base de datos queda inaccesible |
| **Mitigación** | Habilitar Multi-AZ para RDS (aumenta costo ~100%) |

### RISK-OPS-004: No hay backup automático de EC2 más allá de DLM

| Atributo | Valor |
|----------|-------|
| **Severidad** | BAJO |
| **Módulo** | `modules/compute` |
| **Descripción** | Los snapshots EBS son automáticos (7 días), pero no hay AMI backup de la instancia completa |
| **Impacto** | Restaurar instancia requiere recrear desde snapshot + AMI manual |
| **Mitigación** | Implementar AWS Backup para crear AMIs automáticas |

---

## Riesgos de Disponibilidad

### RISK-AVAIL-001: Punto único de falla en EC2

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/compute` |
| **Descripción** | EC2 es una instancia única sin auto scaling ni multi-AZ |
| **Impacto** | Si la instancia falla, la aplicación queda inaccesible |
| **Mitigación** | Implementar ASG con mínimo 1 instancia en 2 AZs, con ALB health checks |

### RISK-AVAIL-002: CloudFront como punto de entrada único

| Atributo | Valor |
|----------|-------|
| **Severidad** | BAJO |
| **Módulo** | `modules/cloudfront` |
| **Descripción** | CloudFront es el único punto de entrada público |
| **Impacto** | Si CloudFront falla (raro), la aplicación queda inaccesible. AWS tiene alta disponibilidad para CloudFront |
| **Mitigación** | CloudFront tiene alta disponibilidad inherente. Considerar tener un DNS failover al ALB como backup |

### RISK-AVAIL-003: Sin Route 53 health checks ni failover

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | No implementado |
| **Descripción** | No hay health checks de Route 53 ni configuración de failover DNS |
| **Impacto** | Si CloudFront falla, no hay failover automático |
| **Mitigación** | Implementar Route 53 con health checks y failover routing |

---

## Cambios Terraform Peligrosos

Los siguientes cambios en variables fuerzaN la recreación de recursos (destructivo):

| Variable | Recurso Afectado | Tipo de Cambio |
|----------|------------------|----------------|
| `vpc_cidr` | VPC + TODA la infraestructura | Cambio de CIDR |
| `public_subnet_cidr` | Subnet + recursos dependientes | Cambio de CIDR |
| `private_subnet_cidr` | Subnet + EC2, RDS | Cambio de CIDR |
| `public_subnet_az` | Subnet + ALB, NAT | Cambio de AZ |
| `private_subnet_az` | Subnet + EC2 | Cambio de AZ |
| `ec2_instance_type` | EC2 Instance | Cambio de tipo |
| `rds_instance_class` | RDS Instance | Cambio de tipo |
| `rds_engine_version` | RDS Instance | Upgrade mayor |
| `rds_storage_type` | RDS Instance | Cambio de storage |
| `s3_bucket_name` | S3 Bucket | Cambio de nombre |
| `ecr_repository_name` | ECR Repository | Cambio de nombre |
| `origin_domain_name` en CloudFront | CloudFront | Cambio de origen |
| `enable_nat_gateway` (false→true) | NAT GW, EIP, Routes | Creación |
| `enable_nat_gateway` (true→false) | NAT GW, EIP, Routes | Destrucción |