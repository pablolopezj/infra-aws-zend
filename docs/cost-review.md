# Cost Review - infra-aws-zend

> **Fecha**: 2026-05-16 | **Región**: mx-central-1 | **Moneda**: USD

## Estimación Mensual Total

| Componente | Costo Mensual (USD) | % del Total | Notas |
|-----------|---------------------|-------------|--------|
| EC2 (t4g.medium) | $30.37 | 20% | 744 horas/mes, bajo demanda |
| RDS (db.t4g.medium) | $51.02 | 34% | 744 horas/mes, 200GB gp3 |
| NAT Gateway | $32.00 | 21% | $0.045/hr + datos |
| ALB | $16.20 | 11% | $0.0225/hr + LCU |
| CloudFront | $4.50 | 3% | ~50GB datos + 1M requests |
| EBS (EC2) | $11.00 | 7% | 30GB root + 100GB data gp3 |
| WAF | $5.00 | 3% | 1 Web ACL + managed rules |
| S3 | $4.60 | 3% | Lifecycle: Standard → Glacier IR |
| ECR | $1.00 | <1% | ~1-10GB almacenamiento |
| DLM Snapshots | $1.50 | 1% | 7 snapshots × ~0.5GB × 30 días |
| Secrets Manager | $0.40 | <1% | 1 secreto |
| CloudWatch | $0.00 | 0% | Métricas básicas gratuitas |
| **Backend (S3+DynamoDB)** | **$0.50** | **<1%** | State backend |
| **TOTAL ESTIMADO** | **~$157/mes** | **100%** | Sin IPv4 charges, sin data transfer |

> Nota: Los costos son estimaciones basadas en precios de AWS bajo demanda en mx-central-1. Los costos reales pueden variar por transferencia de datos, requesting patterns, y cambios de precio.

---

## Desglose Detallado por Servicio

### EC2 (Compute)

| Recurso | Especificación | Costo/Mes | Notas |
|---------|---------------|-----------|-------|
| Instancia EC2 | t4g.medium (ARM64) | $30.37 | $0.0408/hr × 744hr |
| Root Volume | 30 GB gp3 | $2.40 | $0.08/GB |
| Data Volume | 100 GB gp3 | $8.00 | $0.08/GB |
| IOPS (gp3) | 3,000 (incluido) | $0.00 | Incluido en gp3 base |
| Throughput (gp3) | 125 MB/s (incluido) | $0.00 | Incluido en gp3 base |
| **Subtotal EC2** | | **$40.77** | |
| Bastion (si habilitado) | t4g.micro | $7.03 | $0.00945/hr × 744hr |
| Bastion root | 30 GB gp3 | $2.40 | $0.08/GB |

**Recomendaciones de optimización**:
- Considerar Savings Plans (1 año: -~30%, 3 años: -~50%)
- Considerar Reserved Instances para cargas estables
- Evaluar si t4g.small es suficiente para desarrollo
- Detener instancias fuera de horario (ahorro potencial: ~50%)

### RDS PostgreSQL

| Recurso | Especificación | Costo/Mes | Notas |
|---------|---------------|-----------|-------|
| Instancia | db.t4g.medium | $51.02 | $0.0685/hr × 744hr |
| Almacenamiento | 200 GB gp3 | $16.00 | $0.08/GB |
| IOPS (gp3) | 3,000 (incluido) | $0.00 | Incluido en gp3 |
| Backups | 7 días | $0.00 | Hasta 200% del almacenamiento gratis |
| **Subtotal RDS** | | **$67.02** | |

**Recomendaciones de optimización**:
- Considerar Reserved Instances (1 año: -~30%)
- Evaluar si db.t4g.small es suficiente para baja carga
- Considerar Aurora Serverless v2 para cargas variables
- Reducir allocated_storage si se usa menos de 200GB

### NAT Gateway

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| NAT Gateway | $32.00 | $0.045/hr × 744hr |
| Data Processing | $0.045-0.09/GB | Primeros 1-10TB |
| Elastic IP | $0.00 | Sin cargo si está asociado a NAT |

**Recomendaciones de optimización**:
- **Mayor impacto**: Agregar VPC Endpoints para SSM, ECR (ahorro potencial: $10-30/mes en data processing)
- Evaluar si se puede eliminar NAT Gateway si no se necesita outbound desde private subnets (usar solo VPC Endpoints)
- Considerar VPC Endpoints de Interface para servicios adicionales

### Application Load Balancer

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| ALB | $16.20 | $0.0225/hr × 744hr |
| LCU (estimado) | $1-5 | Depende del tráfico |
| **Subtotal ALB** | **$17-21** | |

**Recomendaciones de optimización**:
- Si CloudFront siempre apunta al ALB, considerar si se puede eliminar ALB y apuntar CloudFront directamente a EC2 (solo si EC2 está en subnet pública)
- Habilitar deletion protection para evitar eliminación accidental

### CloudFront

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| Data Transfer Out | ~$4.50 | ~50GB × $0.085/GB (PriceClass_100) |
| Requests | ~$0.75 | ~1M requests × $0.0075/10K |
| HTTPS Requests | ~$0.75 | ~1M requests × $0.0075/10K |
| **Subtotal CloudFront** | **~$6.00** | |

**Recomendaciones de optimización**:
- PriceClass_100 está bien para México (solo NA/EU)
- Considerar PriceClass_200 si hay usuarios fuera de NA/EU
- Habilitar compression (ya habilitado) reduce costos de transferencia

### WAF

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| Web ACL | $5.00 | $5/Web ACL/mes |
| Rules | $1.00 | $1/regla/mes (2 managed rules) |
| Requests | ~$0.60 | ~1M requests × $0.60/M |
| **Subtotal WAF** | **~$6.60** | |

**Recomendaciones de optimización**:
- Habilitar rate limiting si sebserven ataques de fuerza bruta
- Considerar custom rules para bloquear tráfico no deseado

### S3

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| Standard Storage | ~$2.30 | ~30GB × $0.023/GB |
| Glacier IR | ~$0.80 | ~20GB × $0.04/GB |
| Requests | ~$0.50 | Estimado |
| Data Transfer | $0.00 | S3 → CloudFront es gratis |
| **Subtotal S3** | **~$3.60** | |

**Recomendaciones de optimización**:
- Lifecycle policy ya configurada (Glacier IR a 30 días) ✅
- Considerar Deep Archive para datos raros de acceso
- Habilitar S3 Request Metrics para monitorear patrones de acceso

### ECR

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| Storage | ~$0.10 | ~1-5 GB × $0.10/GB |
| Lifecycle Policy | ✅ | Mantiene máximo 8-10 imágenes |

**Recomendaciones de optimización**:
- Lifecycle policy ya configurada ✅
- Lifecycle policy elimina untagged images después de 30-60 días ✅

### Secrets Manager

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| 1 Secreto | $0.40 | $0.40/secreto/mes |
| API Calls | ~$0.00 | 10K calls gratis |

**Recomendaciones de optimización**:
- Considerar Parameter Store (tier gratis) si solo se necesita un string simple
- Habilitar rotation automáticamente (costo adicional de Lambda ~$0.20/mes)

### Backend Terraform (S3 + DynamoDB)

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| S3 (state) | ~$0.10 | ~1MB storage + requests |
| DynamoDB (locks) | ~$0.40 | PAY_PER_REQUEST, ~1 write/hour |
| **Subtotal Backend** | **~$0.50** | Muy bajo |

### DLM Snapshots

| Recurso | Costo/Mes | Notas |
|---------|-----------|-------|
| 7 snapshots × 0.5GB | ~$1.50 | $0.05/GB/mes × 7 × ~0.5GB estimado |

---

## Costos por Transferencia de Datos

| Tipo | Origen → Destino | Costo/GB | Estimado/Mes |
|------|-----------------|----------|-------------|
| Internet → CloudFront | Inbound | $0.00 | $0.00 |
| CloudFront → ALB | Origin fetch | $0.00 | $0.00 |
| ALB → EC2 | Intra-VPC | $0.00 | $0.00 |
| CloudFront → Internet | Outbound | $0.085/GB | ~$4.50 (50GB) |
| EC2 → Internet (via NAT) | Outbound | $0.095/GB + NAT $0.045/GB | Variable |
| EC2 → S3 (via VPC Endpoint) | Intra-VPC | $0.00 | $0.00 |
| EC2 → ECR (via NAT) | Outbound | $0.095/GB + NAT $0.045/GB | Variable |

---

## Costos de Direcciones IP Públicas (IPv4)

| Recurso | Tipo | Costo/Mes | Notas |
|---------|-----|-----------|-------|
| NAT Gateway EIP | Pública | $0.00 | Sin cargo si está asociado |
| EC2 (si en pública) | Pública | $3.60 | $0.005/hr × 744hr (si tiene IP pública) |
| ALB | No aplica | $0.00 | ALB usa IPs variables |

> AWS cobra por todas las direcciones IPv4 públicas, incluyendo las asociadas a instancias EC2. Si EC2 está en subnet privada (como en este caso), no tiene IP pública y no se cobra.

---

## Escenarios de Costo

### Escenario 1: Mínimo (sin ALB/CloudFront/WAF)

| Componente | Costo/Mes |
|-----------|-----------|
| EC2 t4g.medium | $30.37 |
| EBS (30+100GB) | $10.40 |
| RDS db.t4g.medium | $67.02 |
| NAT Gateway | $32.00 |
| S3 | $3.60 |
| ECR | $0.10 |
| Secrets Manager | $0.40 |
| DLM | $1.50 |
| **Total** | **~$145/mes** |

### Escenario 2: Producción Completa (configuración actual)

| Componente | Costo/Mes |
|-----------|-----------|
| Escenario 1 | $145 |
| ALB | $17-21 |
| CloudFront | $6 |
| WAF | $6.60 |
| **Total** | **~$175-180/mes** |

### Escenario 3: Optimizado

| Componente | Costo/Mes | Ahorro |
|-----------|-----------|--------|
| EC2 Reserved (1yr) | $21.26 | -$15 |
| RDS Reserved (1yr) | $35.71 | -$20 |
| Eliminar NAT Gateway (solo Endpoints) | $0 | -$32 |
| CloudFront | $6 | - |
| ALB | $18 | - |
| WAF | $6.60 | - |
| S3 + ECR + SM + DLM | $5.60 | - |
| **Total Optimizado** | **~$93/mes** | **Ahorro ~$87/mes** |

---

## Recomendaciones de Optimización

### Alto Impacto

1. **Reserved Instances para EC2 y RDS**: Ahorro de ~30-50% en compute
2. **VPC Endpoints para SSM/ECR**: Reduce data processing por NAT Gateway
3. **Evaluar eliminación de NAT Gateway**: Si solo se usa para outbound, reemplazar con VPC Endpoints

### Medio Impacto

4. **S3 Lifecycle**: Ya configurado con Glacier IR a 30 días ✅
5. **ECR Lifecycle**: Ya configurado con max 8 imágenes y cleanup de untagged ✅
6. **RDS Storage**: Reducir allocated_storage si se usa menos de 200GB
7. **CloudFront compression**: Ya habilitado ✅

### Bajo Impacto

8. **S3 Versioning**: Habilitar solo si es necesario (aumenta storage ~2x)
9. **CloudWatch Logs**:Evaluar costo antes de habilitar logs extensos
10. **EBS Snapshots**: Mantener solo 7 días ✅, evaluar reducir a 3-5 días