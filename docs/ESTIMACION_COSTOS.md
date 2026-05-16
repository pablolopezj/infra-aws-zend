# Estimación de Costos Mensuales - Proyecto AWS Zend

## 📊 Resumen Ejecutivo

**Costo Total Estimado: ~$180-220 USD/mes**

Basado en las configuraciones actuales del proyecto con ALB, CloudFront y WAF habilitados.

---

## 💰 Desglose Detallado de Costos

### 1. CloudFront Distribution

**Configuración:**
- Price Class: `PriceClass_100` (US, Canada, Europa)
- Transferencia de datos saliente a Internet: **50 GB/mes**
- Solicitudes HTTPS: **1,000,000/mes**
- Transferencia de datos saliente al origen: **5 GB/mes**

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Transferencia saliente (primeros 10 TB) | 50 GB | $0.085/GB | **$4.25** |
| Solicitudes HTTPS | 1,000,000 | Incluido en transferencia | **$0.00** |
| Transferencia al origen | 5 GB | $0.10/GB | **$0.50** |
| **SUBTOTAL CloudFront** | | | **$4.75** |

**Nota:** Los primeros 1 TB de transferencia saliente tienen un precio reducido. Asumiendo 50 GB/mes, el costo es muy bajo.

---

### 2. AWS WAF (Web Application Firewall)

**Configuración:**
- Web ACLs: **1**
- Reglas agregadas por ACL: **3** (2 AWS Managed + 1 Rate Limiting opcional)
- Grupos de reglas administrados: **1** (AWS Managed Rules)
- Requests procesados: **1,000,000/mes** (mismo que CloudFront)

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Web ACL (base) | 1 | $5.00/mes | **$5.00** |
| Reglas (primeras 5 incluidas) | 3 | $0.00 (incluidas) | **$0.00** |
| Requests procesados (primer 1M) | 1,000,000 | $1.00/1M requests | **$1.00** |
| **SUBTOTAL WAF** | | | **$6.00** |

**Nota:** Si habilitas Rate Limiting (`waf_enable_rate_limiting = true`), el costo se mantiene igual ya que las primeras 5 reglas están incluidas.

---

### 3. Application Load Balancer (ALB)

**Configuración:**
- Tipo: Application Load Balancer (internet-facing)
- Capacidad Units (LCU): Variable según tráfico
- Health checks: Habilitados

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| ALB (base) | 1 | $0.0225/hora × 730 horas | **$16.43** |
| LCU (estimado para 1M requests) | ~2-3 LCU | $0.008/LCU-hora × 730 horas | **$11.68 - $17.52** |
| **SUBTOTAL ALB** | | | **$28.11 - $33.95** |

**Nota:** LCU varía según:
- New connections: ~0.5 LCU (1M requests/mes = ~0.35 req/seg)
- Active connections: ~0.5 LCU
- Processed bytes: ~1-2 LCU (50 GB transferencia)

**Estimación conservadora: $30/mes**

---

### 4. EC2 Instances

#### 4.1. Instancia Principal (zend-app)

**Configuración:**
- Tipo: `t4g.medium`
- Tenencia: Shared (On-Demand)
- Horas al mes: 730 horas
- Monitoring: Deshabilitado

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| EC2 t4g.medium (On-Demand) | 730 horas | $0.0336/hora | **$24.53** |
| **SUBTOTAL EC2 Principal** | | | **$24.53** |

#### 4.2. Bastion Host

**Configuración:**
- Tipo: `t4g.micro`
- Horas al mes: 730 horas

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| EC2 t4g.micro (On-Demand) | 730 horas | $0.0084/hora | **$6.13** |
| Elastic IP (si está asociado) | 1 | $0.00 (si está en uso) | **$0.00** |
| **SUBTOTAL Bastion** | | | **$6.13** |

**SUBTOTAL EC2 Total: $30.66/mes**

---

### 5. EBS Volumes

#### 5.1. Root Volume (EC2 Principal)

**Configuración:**
- Tipo: gp3
- Tamaño: 20 GB
- IOPS: 3,000 (provisioned)
- Throughput: 125 MBps

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Almacenamiento gp3 | 20 GB | $0.08/GB-mes | **$1.60** |
| IOPS provisionados (>3,000) | 0 GB (incluidos 3,000) | $0.005/IOPS-mes | **$0.00** |
| Throughput (>125 MBps) | 0 GB (incluido 125 MBps) | $0.04/MBps-mes | **$0.00** |
| **SUBTOTAL Root Volume** | | | **$1.60** |

#### 5.2. Data Volume (EC2 Principal)

**Configuración:**
- Tipo: gp3
- Tamaño: 100 GB
- IOPS: 3,000 (provisioned)
- Throughput: 125 MBps

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Almacenamiento gp3 | 100 GB | $0.08/GB-mes | **$8.00** |
| IOPS provisionados (>3,000) | 0 GB (incluidos 3,000) | $0.005/IOPS-mes | **$0.00** |
| Throughput (>125 MBps) | 0 GB (incluido 125 MBps) | $0.04/MBps-mes | **$0.00** |
| **SUBTOTAL Data Volume** | | | **$8.00** |

#### 5.3. EBS Snapshots

**Configuración:**
- Frecuencia: 1 vez al día
- Retención: 7 días
- Tamaño promedio por snapshot: 3 GB (cambios incrementales)
- Total de snapshots: 7 snapshots × 3 GB = 21 GB promedio

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Snapshots almacenados | 21 GB | $0.05/GB-mes | **$1.05** |
| **SUBTOTAL Snapshots** | | | **$1.05** |

**SUBTOTAL EBS Total: $10.65/mes**

---

### 6. S3 Bucket

**Configuración:**
- Almacenamiento S3 Standard: **200 GB/mes**
- Almacenamiento Glacier Instant Retrieval: **800 GB/mes**
- Requests PUT/COPY/POST/LIST (S3 Standard): **10,000/mes**
- Requests GET/SELECT (S3 Standard): **50,000/mes**
- Requests PUT/COPY/POST/LIST (Glacier IR): **2,000/mes**
- Requests GET/SELECT (Glacier IR): **500/mes**
- Lifecycle transitions: **2,000/mes**
- Data retrievals (Glacier IR): **10 GB/mes**
- Versioning: Deshabilitado

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| **S3 Standard** | | | |
| Almacenamiento | 200 GB | $0.023/GB-mes | **$4.60** |
| PUT/COPY/POST/LIST | 10,000 | $0.005/1,000 requests | **$0.05** |
| GET/SELECT | 50,000 | $0.0004/1,000 requests | **$0.02** |
| **Glacier Instant Retrieval** | | | |
| Almacenamiento | 800 GB | $0.004/GB-mes | **$3.20** |
| PUT/COPY/POST/LIST | 2,000 | $0.01/1,000 requests | **$0.02** |
| GET/SELECT | 500 | $0.0004/1,000 requests | **$0.00** |
| Data retrievals | 10 GB | $0.03/GB | **$0.30** |
| **Lifecycle** | | | |
| Transitions | 2,000 | $0.00 (gratis) | **$0.00** |
| **SUBTOTAL S3** | | | **$8.19** |

---

### 7. RDS PostgreSQL (Comentado - No se incluye en total)

**Configuración (comentada en código):**
- Tipo: `db.t4g.medium`
- Almacenamiento: 200 GB gp3
- Single-AZ
- Backup retention: 7 días
- Performance Insights: Deshabilitado

**Cálculo de Costos (solo referencia):**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Instancia db.t4g.medium | 730 horas | $0.072/hora | **$52.56** |
| Almacenamiento gp3 (200 GB) | 200 GB | $0.115/GB-mes | **$23.00** |
| Backups (7 días) | ~14 GB | $0.095/GB-mes | **$1.33** |
| **SUBTOTAL RDS** | | | **$76.89** |

**Nota:** RDS está comentado en el código, por lo que NO se incluye en el total.

---

### 8. Networking (VPC, Subnets, IGW)

**Configuración:**
- VPC: 1
- Subnets: 2 (pública y privada)
- Internet Gateway: 1
- Route Tables: 2
- Security Groups: 2
- Network ACLs: 2
- VPC Endpoints: 2 (S3, DynamoDB - Gateway type)

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| VPC | 1 | $0.00 (gratis) | **$0.00** |
| Subnets | 2 | $0.00 (gratis) | **$0.00** |
| Internet Gateway | 1 | $0.00 (gratis) | **$0.00** |
| Route Tables | 2 | $0.00 (gratis) | **$0.00** |
| Security Groups | 2 | $0.00 (gratis) | **$0.00** |
| Network ACLs | 2 | $0.00 (gratis) | **$0.00** |
| VPC Endpoints (Gateway) | 2 | $0.00 (gratis) | **$0.00** |
| **SUBTOTAL Networking** | | | **$0.00** |

**Nota:** VPC Endpoints tipo Gateway (S3, DynamoDB) son gratuitos.

---

### 9. Data Transfer

**Configuración:**
- Transferencia dentro de la misma región: Mínima (todo dentro de mx-central-1)
- Transferencia saliente a Internet: Incluida en CloudFront
- Transferencia entre servicios: Mínima

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| Transferencia intra-región | <1 GB | $0.01/GB | **$0.00** |
| Transferencia saliente | Incluida en CloudFront | - | **$0.00** |
| **SUBTOTAL Data Transfer** | | | **$0.00** |

---

### 10. Otros Servicios

#### 10.1. Data Lifecycle Manager (DLM)

**Configuración:**
- Política de snapshots: 1
- Snapshots automáticos: 1/día

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| DLM Policy | 1 | $0.00 (gratis) | **$0.00** |
| **SUBTOTAL DLM** | | | **$0.00** |

**Nota:** DLM es gratuito, solo pagas por el almacenamiento de snapshots (ya incluido en EBS).

#### 10.2. IAM Roles y Policies

**Configuración:**
- IAM Roles: 1 (EC2 S3 access)
- IAM Policies: 1

**Cálculo de Costos:**

| Concepto | Cantidad | Precio Unitario | Costo Mensual |
|---------|----------|-----------------|---------------|
| IAM | - | $0.00 (gratis) | **$0.00** |
| **SUBTOTAL IAM** | | | **$0.00** |

---

## 📊 Resumen Total de Costos Mensuales

| Servicio | Costo Mensual (USD) |
|----------|---------------------|
| **CloudFront** | $4.75 |
| **WAF** | $6.00 |
| **ALB** | $30.00 |
| **EC2 (Principal + Bastion)** | $30.66 |
| **EBS (Volumes + Snapshots)** | $10.65 |
| **S3** | $8.19 |
| **Networking** | $0.00 |
| **Data Transfer** | $0.00 |
| **Otros (DLM, IAM)** | $0.00 |
| **TOTAL MENSUAL** | **$90.25** |

---

## 💡 Análisis de Costos por Categoría

### Costos Fijos (independientes del tráfico):
- ALB: $30.00/mes
- EC2: $30.66/mes
- EBS: $10.65/mes
- WAF base: $5.00/mes
- **Subtotal Fijo: $76.31/mes**

### Costos Variables (dependen del tráfico):
- CloudFront: $4.75/mes (50 GB transferencia)
- WAF requests: $1.00/mes (1M requests)
- S3: $8.19/mes (200 GB Standard + 800 GB Glacier IR)
- **Subtotal Variable: $13.94/mes**

---

## 📈 Proyecciones de Costo según Tráfico

### Escenario Bajo (25 GB/mes, 500K requests):
- CloudFront: $2.13
- WAF: $5.50
- **Total: ~$85/mes**

### Escenario Actual (50 GB/mes, 1M requests):
- CloudFront: $4.75
- WAF: $6.00
- **Total: ~$90/mes**

### Escenario Alto (100 GB/mes, 2M requests):
- CloudFront: $8.50
- WAF: $7.00
- ALB LCU: +$5.00
- **Total: ~$110/mes**

### Escenario Muy Alto (500 GB/mes, 10M requests):
- CloudFront: $42.50
- WAF: $15.00
- ALB LCU: +$20.00
- **Total: ~$165/mes**

---

## 🎯 Optimizaciones de Costo

### 1. Reducir Costos de ALB
- **Opción A:** Mover EC2 a subnet pública y eliminar ALB
  - Ahorro: ~$30/mes
  - Trade-off: Menos seguridad, sin alta disponibilidad

### 2. Optimizar CloudFront
- **Opción A:** Aumentar caché para reducir transferencia al origen
  - Ahorro potencial: ~$0.50/mes
- **Opción B:** Usar PriceClass_200 en lugar de PriceClass_100
  - Ahorro: ~$1-2/mes
  - Trade-off: Menor cobertura geográfica

### 3. Optimizar S3
- **Opción A:** Aumentar transiciones a Glacier IR más rápido
  - Ahorro potencial: ~$2-3/mes
- **Opción B:** Usar Intelligent-Tiering
  - Ahorro potencial: ~$1-2/mes

### 4. Optimizar EC2
- **Opción A:** Usar Reserved Instances (1 año)
  - Ahorro: ~40% = ~$12/mes
- **Opción B:** Usar Savings Plans
  - Ahorro: ~20-30% = ~$6-9/mes

---

## ⚠️ Costos Adicionales No Incluidos

1. **RDS PostgreSQL** (comentado): ~$77/mes si se habilita
2. **CloudWatch Logs**: ~$0.50/mes (si se habilitan logs)
3. **ACM Certificates**: $0.00 (gratis si se usan)
4. **Route 53**: ~$0.50/mes (si se usa dominio personalizado)
5. **Backup adicionales**: Variable según necesidad

---

## 📝 Notas Importantes

1. **Precios en USD**: Todos los precios están en dólares estadounidenses
2. **Región**: mx-central-1 (México Central)
3. **IVA/Impuestos**: No incluidos (agregar según tu país)
4. **Free Tier**: No se aplica (asumiendo cuenta sin free tier)
5. **Variabilidad**: Los costos pueden variar según uso real

---

## 🔄 Actualización de Costos

Esta estimación se basa en:
- Configuraciones actuales del proyecto
- Precios de AWS (diciembre 2024)
- Uso estimado según especificaciones

**Recomendación:** Revisar mensualmente los costos reales en AWS Cost Explorer y ajustar según necesidad.

---

**Última actualización:** Diciembre 2024

