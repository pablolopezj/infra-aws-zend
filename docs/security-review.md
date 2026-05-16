# Security Review - infra-aws-zend

> **Fecha de revisión**: 2026-05-16 | **Basado en**: Análisis del código Terraform

## Resumen Ejecutivo

| Severidad | Cantidad |
|-----------|----------|
| Crítico | 1 |
| Alto | 5 |
| Medio | 6 |
| Bajo | 3 |

---

## Hallazgo Crítico

### SEC-CRIT-001: Contraseña RDS hardcodeada en terraform.tfvars

| Atributo | Valor |
|----------|-------|
| **Severidad** | CRÍTICO |
| **Módulo** | `envs/prod/terraform.tfvars` |
| **Archivo** | `terraform.tfvars` línea 20 |
| **Descripción** | La contraseña maestra de RDS está hardcodeada en texto plano: `rds_master_password = "Sc0rp1on2025!"` |
| **Impacto** | Cualquier persona con acceso al repositorio puede ver la contraseña de la base de datos de producción |
| **Remediación** | (1) Eliminar la contraseña del tfvars, (2) usar `random_password` exclusivamente (ya existe en el código), (3) agregar `terraform.tfvars` al `.gitignore` si no está, (4) rotar la contraseña inmediatamente en Secrets Manager |

**Nota**: Aunque el código utiliza `random_password` para generar la contraseña, el valor `rds_master_password` del tfvars podría ser referenciado en algún lugar. El módulo RDS usa `random_password.rds_master.result` directamente, por lo que la variable `rds_master_password` del tfvars parece no usarse en la configuración actual. Sin embargo, el hecho de que esté en el archivo es un riesgo.

---

## Hallazgos Altos

### SEC-HIGH-001: NACL Público permite SSH desde 0.0.0.0/0

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network/main.tf` |
| **Descripción** | La regla 115 del NACL público permite tráfico SSH (puerto 22) desde `0.0.0.0/0` |
| **Impacto** | Cualquier IP puede intentar conexiones SSH a instancias en la subnet pública, incluyendo el bastion host |
| **Remediación** | Eliminar la regla 115 o restringir a rangos de IP específicos |

### SEC-HIGH-002: Bastion SSH default permite 0.0.0.0/0

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/bastion/variables.tf` |
| **Variable** | `allowed_ssh_cidrs` |
| **Default** | `["0.0.0.0/0"]` |
| **Descripción** | El SG del bastion permite SSH desde cualquier IP por defecto |
| **Impacto** | Si `enable_bastion = true` sin override, SSH está abierto al mundo |
| **Remediación** | Cambiar el default a una lista vacía `[]` y requerir que se especifiquen IPs explícitamente. En producción, usar solo IPs específicas. |

### SEC-HIGH-003: NACLs permiten ICMP desde 0.0.0.0/0

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network/main.tf` |
| **Descripción** | Tanto el NACL público como el privado permiten ICMP (ping) desde 0.0.0.0/0 (reglas 130) |
| **Impacto** | Permite escaneo de la infraestructura y reconacimiento de red |
| **Remediación** | Eliminar las reglas ICMP o restringirlas a rangos de IP administrativos |

### SEC-HIGH-004: NACLs permiten puertos efímeros amplios desde 0.0.0.0/0

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network/main.tf` |
| **Descripción** | Los NACLs permiten TCP y UDP en todos los puertos (0-65535) desde 0.0.0.0/0 (reglas 125 y 127) |
| **Impacto** | Reduce significativamente la efectividad del NACL como capa de seguridad |
| **Remediación** | Restringir los puertos efímeros al rango 1024-65535 y limitar a IPs específicas |

### SEC-HIGH-005: SG Privado permite todo el tráfico VPC

| Atributo | Valor |
|----------|-------|
| **Severidad** | ALTO |
| **Módulo** | `modules/network/main.tf` |
| **Descripción** | El SG privado tiene una regla ingress que permite todo el tráfico (`protocol = "-1"`) desde el CIDR completo de la VPC |
| **Impacto** | Cualquier recurso en la VPC puede acceder a cualquier puerto de instancias en la subnet privada |
| **Remediación** | Reemplazar la regla broad con reglas específicas por puerto y SG |

---

## Hallazgos Medios

### SEC-MED-001: DLM IAM Policy usa Resource = "*"

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/compute/main.tf` |
| **Descripción** | La IAM policy del rol DLM usa `Resource = "*"` para acciones de EC2 snapshot |
| **Impacto** | El rol DLM podría usarse para crear o eliminar snapshots de cualquier volumen |
| **Remediación** | Restringir el Resource a los ARNs específicos de los volúmenes EBS |

### SEC-MED-002: WAF Rate Limiting deshabilitado por defecto

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/waf/variables.tf` |
| **Variable** | `enable_rate_limiting` |
| **Default** | `false` |
| **Descripción** | El rate limiting del WAF está deshabilitado por defecto |
| **Impacto** | La aplicación es vulnerable a ataques de fuerza bruta y DDoS a nivel de aplicación |
| **Remediación** | Habilitar `waf_enable_rate_limiting = true` en producción con un límite adecuado |

### SEC-MED-003: ALB Deletion Protection deshabilitado

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` |
| **Descripción** | `enable_deletion_protection = false` explícitamente en el código de producción |
| **Impacto** | El ALB puede ser eliminado accidentalmente con `terraform destroy` |
| **Remediación** | Cambiar a `true` en producción. Agregar variable con default `false` para dev/staging |

### SEC-MED-004: RDS SG permite acceso desde VPC CIDR completa

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/rds/main.tf` |
| **Descripción** | El SG de RDS tiene una regla ingress que permite PostgreSQL (5432) desde todo el CIDR de la VPC |
| **Impacto** | Cualquier recurso en la VPC puede conectarse a la base de datos |
| **Remediación** | Eliminar la regla de VPC CIDR y mantener solo la regla de Security Groups específicos |

### SEC-MED-005: CloudFront sin logging habilitado

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `modules/cloudfront/variables.tf` |
| **Variable** | `enable_logging` |
| **Default** | `false` |
| **Descripción** | CloudFront no tiene access logging habilitado por defecto |
| **Impacto** | Dificulta el análisis forense, detección de ataques y auditoría |
| **Remediación** | Habilitar logging a un bucket S3 dedicado |

### SEC-MED-006: ALB sin HTTPS listener (certificado no configurado)

| Atributo | Valor |
|----------|-------|
| **Severidad** | MEDIO |
| **Módulo** | `envs/prod/main.tf` |
| **Variable** | `alb_certificate_arn` |
| **Valor** | `""` (vacío) |
| **Descripción** | El ALB solo escucha en HTTP (puerto 80), sin HTTPS. CloudFront maneja HTTPS, pero el tráfico CloudFront → ALB es HTTP sin cifrar |
| **Impacto** | Tráfico sin cifrar entre CloudFront y ALB |
| **Remediación** | Configurar certificado ACM en us-west-1/mx-central-1 para el ALB y habilitar HTTPS listener |

---

## Hallazgos Bajos

### SEC-LOW-001: S3 Bucket versioning deshabilitado por defecto

| Atributo | Valor |
|----------|-------|
| **Severidad** | BAJO |
| **Módulo** | `envs/prod/variables.tf` |
| **Variable** | `s3_enable_versioning` |
| **Default** | `false` |
| **Descripción** | El versionado del bucket S3 está deshabilitado por defecto en prod, pero habilitado en el módulo S3 por defecto |
| **Impacto** | Sin versionado, no se puede recuperar objetos sobrescritos o eliminados accidentalmente |
| **Remediación** | Habilitar versionado en producción |

### SEC-LOW-002: EC2 monitoring deshabilitado

| Atributo | Valor |
|----------|-------|
| **Severidad** | BAJO |
| **Módulo** | `envs/prod/main.tf` |
| **Variable** | `monitoring_enabled` |
| **Valor** | `false` |
| **Descripción** | CloudWatch detailed monitoring está deshabilitado para EC2 |
| **Impacto** | Métricas con granularidad de 5 minutos en lugar de 1 minuto |
| **Remediación** | Habilitar en producción para mejor observabilidad |

### SEC-LOW-003: ECR tag mutability configurada como MUTABLE

| Atributo | Valor |
|----------|-------|
| **Severidad** | BAJO |
| **Módulo** | `envs/prod/terraform.tfvars` |
| **Valor** | `ecr_image_tag_mutability = "MUTABLE"` |
| **Descripción** | Los tags de imágenes ECR pueden ser sobrescritos |
| **Impacto** | Riesgo de que una imagen sea sobrescrita inadvertidamente |
| **Remediación** | Considerar `IMMUTABLE` en producción para garantizar integridad |

---

## Exposición Pública

| Recurso | Puerto | Origen | Estado |
|---------|--------|--------|--------|
| CloudFront | 443/80 | Internet (a través de WAF) | ✅ Esperado |
| ALB | 80 | Internet (a través de CloudFront) | ✅ Esperado |
| NACL Público SSH | 22 | 0.0.0.0/0 | ⚠️ Restrictivo recomendado |
| NACL Público HTTP/S | 80, 443 | 0.0.0.0/0 | ✅ Esperado |
| SG Público | 80, 443 | 0.0.0.0/0 | ✅ Esperado |
| Bastion SSH | 22 | Configurable (default 0.0.0.0/0) | ⚠️ |
| RDS | 5432 | Solo VPC CIDR + SG EC2 | ✅ Privado |

## IAM Least Privilege

| Rol/Policy | Permiso | Scope | Evaluación |
|------------|---------|-------|------------|
| EC2 S3 Role | s3:GetObject, PutObject, DeleteObject, ListBucket, etc. | Bucket específico | ✅ Aceptable |
| EC2 S3 Role | ecr:GetDownloadUrlForLayer, etc. (AmazonEC2ContainerRegistryReadOnly) | Todos los repos ECR | ⚠️ Podría ser más restrictivo |
| EC2 S3 Role | ssm:* (AmazonSSMManagedInstanceCore) | Todos los recursos SSM | ✅ Política administrada |
| EC2 Secrets Role | secretsmanager:GetSecretValue, DescribeSecret | Secreto RDS específico | ✅ Aceptable |
| DLM Role | ec2:CreateSnapshot, CreateSnapshots, DeleteSnapshot, Describe* | Todos los recursos (*) | ⚠️ Demasiado amplio |
| DLM Role | ec2:CreateTags | Todos los snapshots (*) | ⚠️ Podría ser más restrictivo |

## TLS/ACM

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Certificado CloudFront | ✅ Configurado | ACM en us-east-1, ARN hardcodeado |
| Dominios SSL | ✅ Configurado | scorpionpys.mx + www.scorpionpys.mx |
| Viewer Protocol | ✅ Configurado | redirect-to-https (HTTP → HTTPS) |
| Origin Protocol | ⚠️ HTTP only | CloudFront → ALB es HTTP (sin cert en ALB) |
| Mínimo TLS | ✅ Configurado | TLSv1.2_2021 |
| Certificado ALB | ❌ No configurado | ALB solo escucha HTTP (puerto 80) |

## Secrets Manager

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Secreto RDS | ✅ Creado | Auto-generado con `random_password` |
| Contenido | ✅ Completo | username, password, engine, host, port, dbname |
| Tipo de password | ✅ Seguro | 16 caracteres, especiales `!#$%&*()-_=+[]{}<>:?` |
| Rotación | ❌ No configurada | No hay Lambda de rotación automática |
| Acceso EC2 | ✅ Restringido | Policy específica al secreto RDS |

## WAF

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| WAF habilitado | ✅ Sí | Scope CLOUDFRONT, us-east-1 |
| Reglas Managed | ✅ 2 reglas | AWSManagedRulesCommonRuleSet + KnownBadInputsRuleSet |
| Rate Limiting | ❌ Deshabilitado | `waf_enable_rate_limiting = false` |
| CloudWatch Metrics | ✅ Habilitado | |
| Sampled Requests | ✅ Habilitado | |
| IP Sets | ❌ No configurados | Sin allowlist ni blocklist |
| Custom Rules | ❌ No configuradas | |
| Geo Restriction | ❌ No configurado | CloudFront permite todo |

## S3 Public Access Block

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Block Public ACLs | ✅ true | Bucket de aplicación |
| Block Public Policy | ✅ true | Bucket de aplicación |
| Ignore Public ACLs | ✅ true | Bucket de aplicación |
| Restrict Public Buckets | ✅ true | Bucket de aplicación |

## Outputs Sensibles

| Output | Tipo | Sensible | Notas |
|--------|------|----------|-------|
| `rds_instance_username` | string | `sensitive = true` | ✅ Correcto |
| `ec2_instance_public_ip` | string | No marcado | ⚠️ Podría contener IP sensible |
| `nat_gateway_public_ip` | string | No marcado | ⚠️ IP pública visible |
| `bastion_public_ip` | string | No marcado | ⚠️ IP sensible si bastion está habilitado |

## Resumen de Recomendaciones Prioritarias

1. **P0**: Eliminar contraseña RDS de `terraform.tfvars` y rotar la contraseña existente ✓
2. **P1**: Restringir NACLs (eliminar SSH abierto, ICMP, puertos efímeros amplios)
3. **P1**: Cambiar default de `bastion_allowed_ssh_cidrs` de `["0.0.0.0/0"]` a `[]`
4. **P1**: Habilitar WAF rate limiting en producción
5. **P1**: Restringir SG privado a puertos específicos en lugar de todo el tráfico VPC
6. **P2**: Habilitar deletion protection en ALB para producción
7. **P2**: Habilitar CloudFront access logging
8. **P2**: Configurar HTTPS en ALB (certificado ACM en mx-central-1)
9. **P2**: Habilitar S3 versioning en bucket de aplicación
10. **P3**: Habilitar Secrets Manager rotation para credenciales RDS