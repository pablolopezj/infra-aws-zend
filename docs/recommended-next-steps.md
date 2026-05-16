# Recommended Next Steps - infra-aws-zend

> **Priorización**: P0 (crítico), P1 (alto), P2 (medio), P3 (bajo)

## Resumen de Prioridades

| Prioridad | Cantidad | Beneficio Principal |
|-----------|----------|---------------------|
| P0 | 1 | Seguridad crítica |
| P1 | 4 | Seguridad y estabilidad |
| P2 | 5 | Operacional y costos |
| P3 | 3 | Mejora a largo plazo |

---

## P0 - Crítico (Implementar Inmediatamente)

### STEP-001: Eliminar contraseña RDS del repositorio

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P0 - Crítico |
| **Beneficio** | Seguridad: elimina credenciales expuestas |
| **Dificultad** | Baja |
| **Riesgo** | Ninguno |
| **Módulos afectados** | `envs/prod/terraform.tfvars` |
| **Tiempo estimado** | 15 minutos |

**Acciones**:
1. Eliminar `rds_master_password = "Sc0rp1on2025!"` de `terraform.tfvars`
2. Verificar que `.gitignore` incluye `*.tfvars` (ya está incluido)
3. Rotar la contraseña actual en Secrets Manager
4. Si el password fue commitado al historial de git, considerar rotar y limpiar historial
5. El módulo RDS ya usa `random_password`, por lo que no se necesita el valor en tfvars

**Comandos**:
```bash
# Verificar que el tfvars ya no tiene la contraseña
grep -i "password" envs/prod/terraform.tfvars

# Rotar contraseña en Secrets Manager (después de apply)
aws secretsmanager rotate-secret \
  --secret-id zend-app-prod-mxc1-rds-credentials \
  --region mx-central-1
```

---

## P1 - Alto (Implementar en las próximas semanas)

### STEP-002: Restringir NACLs y Security Groups

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P1 - Alto |
| **Beneficio** | Seguridad: reduce superficie de ataque |
| **Dificultad** | Media |
| **Riesgo** | Puede romper conectividad si se restringe demasiado |
| **Módulos afectados** | `modules/network` |
| **Tiempo estimado** | 2-3 horas |

**Acciones**:
1. Eliminar regla NACL 115 (SSH desde 0.0.0.0/0)
2. Eliminar reglas NACL 125, 127 (puertos efímeros amplios desde 0.0.0.0/0) y reemplazar con rango 1024-65535 desde VPC CIDR
3. Eliminar reglas NACL 130 (ICMP desde 0.0.0.0/0)
4. Restringir SG privado de `protocol="-1"` a puertos específicos:
   - 80 desde SG ALB
   - 443 desde SG ALB
   - 5432 desde SG RDS
   - 22 desde SG Bastion (si habilitado)
5. Cambiar default de `bastion_allowed_ssh_cidrs` de `["0.0.0.0/0"]` a `[]`
6. Eliminar regla de RDS SG que permite acceso desde VPC CIDR completo

### STEP-003: Habilitar WAF Rate Limiting

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P1 - Alto |
| **Beneficio** | Seguridad: protección contra DDoS y fuerza bruta |
| **Dificultad** | Baja |
| **Riesgo** | Puede bloquear tráfico legítimo si el límite es muy bajo |
| **Módulos afectados** | `modules/waf`, `envs/prod/variables.tf` |
| **Tiempo estimado** | 30 minutos |

**Acciones**:
1. Agregar `waf_enable_rate_limiting = true` a `terraform.tfvars`
2. Ajustar `waf_rate_limit` según tráfico esperado (ej. 2000 requests/5min)
3. Monitorear WAF metrics para ajustar el límite

### STEP-004: Habilitar ALB Deletion Protection

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P1 - Alto |
| **Beneficio** | Operacional: previene eliminación accidental del ALB |
| **Dificultad** | Baja |
| **Riesgo** | Ninguno (requiere deshabilitar antes de eliminar) |
| **Módulos afectados** | `envs/prod/main.tf` |
| **Tiempo estimado** | 15 minutos |

**Acciones**:
1. Cambiar `enable_deletion_protection = false` a `true` en `envs/prod/main.tf`
2. O convertirlo en variable con default `true` para producción y `false` para desarrollo

### STEP-005: Configurar Secrets Manager Rotation para RDS

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P1 - Alto |
| **Beneficio** | Seguridad: rotación automática de credenciales |
| **Dificultad** | Media |
| **Riesgo** | Rotación causa reinicio breve de RDS |
| **Módulos afectados** | Nuevo módulo o `envs/prod/main.tf` |
| **Tiempo estimado** | 2-3 horas |

**Acciones**:
1. Crear Lambda function para rotación de credenciales RDS
2. Configurar Secrets Manager rotation schedule (ej. 30 días)
3. Verificar que la aplicación puede manejar reconexiones de DB
4. Agregar `aws_secretsmanager_secret_rotation` resource

---

## P2 - Medio (Implementar en próximo trimestre)

### STEP-006: Implementar módulo de Route 53

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P2 - Medio |
| **Beneficio** | Operacional: gestionar DNS como código |
| **Dificultad** | Media |
| **Riesgo** | Cambios DNS pueden causar downtime |
| **Módulos afectados** | Nuevo módulo `modules/route53` |
| **Tiempo estimado** | 4-6 horas |

**Acciones**:
1. Crear módulo `modules/route53` con Hosted Zone y records
2. Crear A record (alias) apuntando a CloudFront distribution
3. Crear A record para `www.scorpionpys.mx`
4. Configurar health checks
5. Verificar propagación DNS

### STEP-007: Implementar módulo de ACM

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P2 - Medio |
| **Beneficio** | Operacional: gestión del certificado SSL como código |
| **Dificultad** | Media |
| **Riesgo** | Certificado debe validarse por DNS |
| **Módulos afectados** | Nuevo módulo `modules/acm` |
| **Tiempo estimado** | 3-4 horas |

**Acciones**:
1. Crear módulo `modules/acm` con `aws_acm_certificate`
2. Configurar validación DNS (requiere Route 53)
3. Actualizar `envs/prod/main.tf` para crear certificado en lugar de hardcodear ARN
4. Agregar provider `aws.us_east_1` para el certificado CloudFront

### STEP-008: Configurar HTTPS end-to-end (ALB)

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P2 - Medio |
| **Beneficio** | Seguridad: cifrado end-to-end |
| **Dificultad** | Media |
| **Riesgo** | Requiere certificado ACM en mx-central-1 |
| **Módulos afectados** | `modules/alb`, `modules/cloudfront` |
| **Tiempo estimado** | 3-4 horas |

**Acciones**:
1. Crear certificado ACM en mx-central-1 para el ALB
2. Actualizar ALB para agregar HTTPS listener con el certificado
3. Actualizar CloudFront origin protocol policy a `https-only`
4. Configurar HTTP → HTTPS redirect en ALB

### STEP-009: Habilitar CloudFront Access Logging

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P2 - Medio |
| **Beneficio** | Operacional: análisis forense y monitoreo |
| **Dificultad** | Baja |
| **Riesgo** | Costo adicional del bucket S3 de logs |
| **Módulos afectados** | `modules/cloudfront` |
| **Tiempo estimado** | 1-2 horas |

**Acciones**:
1. Crear bucket S3 dedicado para logs de CloudFront
2. Habilitar `enable_logging = true` y configurar `logging_bucket`
3. Configurar lifecycle policy para logs (ej. 90 días)
4. Considerar enviar logs a CloudWatch Logs

### STEP-010: Implementar CloudWatch Alarms

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P2 - Medio |
| **Beneficio** | Operacional: alertas automáticas |
| **Dificultad** | Media |
| **Riesgo** | Costo adicional de SNS |
| **Módulos afectados** | Nuevo módulo `modules/monitoring` |
| **Tiempo estimado** | 4-6 horas |

**Acciones**:
1. Crear SNS Topic para notificaciones
2. Crear alarmas para:
   - EC2 CPU > 80%
   - EC2 Status Check failed
   - RDS CPU > 80%
   - RDS Free Storage < 5GB
   - ALB Target Health unhealthy
   - CloudFront 5xx error rate > 5%
   - NAT Gateway Active Connections > threshold
3. Configurar subscriptions (email, Slack, etc.)

---

## P3 - Bajo (Implementar cuando sea conveniente)

### STEP-011: Implementar Auto Scaling Group

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P3 - Bajo |
| **Beneficio** | Disponibilidad: auto-healing y escalabilidad |
| **Dificultad** | Alta |
| **Riesgo** | Cambio arquitectural significativo |
| **Módulos afectados** | `modules/compute` (refactorizar a ASG) |
| **Tiempo estimado** | 8-12 horas |

**Acciones**:
1. Crear Launch Template con la configuración actual de EC2
2. Crear ASG con min 1, max 2, desired 1
3. Configurar ALB Target Group attachment automático
4. Agregar ASG scaling policies (CPU, request count)
5. Crear AMI con Packer o usar user data avanzado

### STEP-012: Habilitar RDS Multi-AZ

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P3 - Bajo |
| **Beneficio** | Disponibilidad: failover automático |
| **Dificultad** | Baja |
| **Riesgo** | Aumento de costo ~100% en RDS |
| **Módulos afectados** | `modules/rds` |
| **Tiempo estimado** | 1-2 horas |

**Acciones**:
1. Agregar variable `multi_az` con default `false`
2. Agregar `multi_az = var.multi_az` al recurso `aws_db_instance`
3. Habilitar en producción después de validar que el costo es aceptable
4. Nota: Cambiar de single-AZ a multi-AZ causa un reinicio breve

### STEP-013: Agregar VPC Endpoints de Interface para SSM

| Atributo | Valor |
|----------|-------|
| **Prioridad** | P3 - Bajo |
| **Beneficio** | Costos: reduce data processing por NAT Gateway |
| **Dificultad** | Media |
| **Riesgo** | Requiere cambios en route tables y SG |
| **Módulos afectados** | `modules/network` |
| **Tiempo estimado** | 2-3 horas |

**Acciones**:
1. Agregar VPC Endpoints de Interface para:
   - `com.amazonaws.mx-central-1.ssm` (Systems Manager)
   - `com.amazonaws.mx-central-1.ssmmessages` (Session Manager)
   - `com.amazonaws.mx-central-1.ec2messages` (EC2 Messages)
   - `com.amazonaws.mx-central-1.ecr.api` (ECR API)
   - `com.amazonaws.mx-central-1.ecr.dkr` (ECR Docker)
2. Configurar SG para los endpoints
3. Agregar route entries si es necesario

---

## Roadmap Sugerido

```mermaid
graph LR
    P0[P0: Eliminar contraseña<br/>del repositorio] --> P1A[P1: Restringir NACLs/SGs]
    P1A --> P1B[P1: Habilitar WAF<br/>Rate Limiting]
    P1B --> P1C[P1: ALB Deletion Protection]
    P1C --> P1D[P1: Secrets Manager<br/>Rotation]
    P1D --> P2A[P2: Módulo Route 53]
    P2A --> P2B[P2: Módulo ACM]
    P2B --> P2C[P2: HTTPS End-to-End]
    P2C --> P2D[P2: CloudFront Logging]
    P2D --> P2E[P2: CloudWatch Alarms]
    P2E --> P3A[P3: Auto Scaling Group]
    P3A --> P3B[P3: RDS Multi-AZ]
    P3B --> P3C[P3: VPC Endpoints<br/>SSM/ECR]
    
    style P0 fill:#FF0000,color:white
    style P1A fill:#FF6600,color:white
    style P1B fill:#FF6600,color:white
    style P1C fill:#FF6600,color:white
    style P1D fill:#FF6600,color:white
    style P2A fill:#FFC000,color:black
    style P2B fill:#FFC000,color:black
    style P2C fill:#FFC000,color:black
    style P2D fill:#FFC000,color:black
    style P2E fill:#FFC000,color:black
    style P3A fill:#70AD47,color:white
    style P3B fill:#70AD47,color:white
    style P3C fill:#70AD47,color:white
```

## Impacto Estimado por Prioridad

| Prioridad | Inversión (horas) | Beneficio Principal |
|-----------|-------------------|---------------------|
| P0 | 0.25 | Seguridad crítica: credenciales expuestas |
| P1 | 5-6 | Seguridad: superficie de ataque reducida |
| P2 | 15-20 | Operacional: DNS como código, HTTPS end-to-end, monitoreo |
| P3 | 11-17 | Disponibilidad y costos a largo plazo |

**Total estimado**: 31-43 horas de trabajo