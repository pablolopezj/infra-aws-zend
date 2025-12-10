# Estimación de Costos Mensuales - Infraestructura Completa

## 📊 Resumen Ejecutivo

**Costo Total Estimado Mensual: $195 - $250 USD/mes**

*(Basado en precios de AWS en mx-central-1, México Central, enero 2025)*

---

## 💰 Desglose Detallado por Servicio

### 1. **Compute (EC2)**

#### Instancia Principal (zend-app-prod-mxc1-ec2)
- **Tipo**: `t4g.medium` (ARM-based, 2 vCPU, 4 GB RAM)
- **Precio**: ~$0.0336/hora
- **Costo mensual**: **$24.50 USD/mes** (730 horas)
- **Nota**: Con Savings Plans (1 año, 20% descuento): ~$19.60/mes

#### Bastion Host (zend-app-prod-mxc1-bastion)
- **Tipo**: `t4g.micro` (ARM-based, 2 vCPU, 1 GB RAM)
- **Precio**: ~$0.0084/hora
- **Costo mensual**: **$6.13 USD/mes** (730 horas)

**Subtotal EC2**: **$30.63 USD/mes**

---

### 2. **Almacenamiento (EBS)**

#### Volúmenes Root (2 instancias)
- **2 x 30GB gp3**: 60 GB × $0.08/GB = **$4.80 USD/mes**

#### Volumen de Datos (EC2 app)
- **100GB gp3**: 100 GB × $0.08/GB = **$8.00 USD/mes**

#### Snapshots Automáticos
- **Retención**: 7 días, 1 snapshot/día
- **Tamaño promedio**: ~130GB
- **Costo**: ~$0.05/GB-mes × 130GB × 7 días / 30 = **$1.52 USD/mes**

**Subtotal EBS**: **$14.32 USD/mes**

---

### 3. **S3 (Almacenamiento de Aplicación)**

#### Almacenamiento
- **S3 Standard**: 200 GB × $0.023/GB = **$4.60 USD/mes**
- **Glacier Instant Retrieval**: 800 GB × $0.005/GB = **$4.00 USD/mes**

#### Requests y Transiciones
- **PUT/GET requests**: ~$0.10/mes
- **Transiciones a Glacier**: ~$0.15/mes

**Subtotal S3**: **$8.85 USD/mes**

---

### 4. **Networking**

#### NAT Gateway
- **Costo base**: $0.045/hora × 730 horas = **$32.85 USD/mes**
- **Transferencia de datos**: ~50 GB/mes × $0.045/GB = **$2.25 USD/mes**
- **Subtotal NAT**: **$35.10 USD/mes**

#### Application Load Balancer (ALB)
- **Costo base**: $0.0225/hora × 730 horas = **$16.43 USD/mes**
- **LCU (Load Balancer Capacity Units)**: ~$5-10/mes (depende del tráfico)
- **Subtotal ALB**: **$21-26 USD/mes**

#### CloudFront
- **Transferencia de datos**: 50 GB × $0.085/GB = **$4.25 USD/mes**
- **Requests**: 1M requests × $0.0075/10K = **$0.75 USD/mes**
- **Subtotal CloudFront**: **$5.00 USD/mes**

**Subtotal Networking**: **$61-66 USD/mes**

---

### 5. **Seguridad y Protección**

#### WAF (Web Application Firewall)
- **Web ACL**: $5.00/mes
- **Managed Rule Groups**: ~$1.00/mes
- **Requests procesados**: 1M × $1.00/1M = **$1.00 USD/mes**
- **Subtotal WAF**: **$7.00 USD/mes**

---

### 6. **Contenedores (ECR)**

#### Almacenamiento
- **10 GB de imágenes Docker**: 10 GB × $0.10/GB = **$1.00 USD/mes**

#### Requests
- **API requests**: ~$0.10/mes

**Subtotal ECR**: **$1.10 USD/mes**

---

### 7. **Base de Datos (RDS PostgreSQL)**

#### Instancia RDS
- **Tipo**: `db.t4g.medium` (2 vCPU, 4 GB RAM)
- **Precio**: ~$0.068/hora × 730 horas = **$49.64 USD/mes**

#### Almacenamiento
- **200 GB gp3**: 200 GB × $0.08/GB = **$16.00 USD/mes**

#### Backups Automáticos
- **Retención**: 7 días
- **200 GB × 7 días**: ~$2.80 USD/mes

#### I/O Requests (gp3)
- **3,000 IOPS base incluidos**: $0.00 USD/mes
- **IOPS adicionales**: ~$0.00/mes (si no excede el base)

#### Performance Insights (si habilitado)
- **Retención 7 días**: **$0.00 USD/mes** (gratis hasta 7 días)

**Subtotal RDS**: **$68.44 USD/mes**

---

### 8. **Backend de Terraform**

#### S3 (Estado de Terraform)
- **Almacenamiento**: ~1 GB × $0.023/GB = **$0.02 USD/mes**
- **Requests**: ~$0.01/mes

#### DynamoDB (State Locking)
- **On-Demand**: ~$0.25/mes (bajo uso)

**Subtotal Backend**: **$0.28 USD/mes**

---

### 9. **Servicios Gratuitos**

- ✅ **VPC**: Gratis
- ✅ **Internet Gateway**: Gratis
- ✅ **VPC Endpoints (S3, DynamoDB)**: Gratis (Gateway endpoints)
- ✅ **Security Groups**: Gratis
- ✅ **Route Tables**: Gratis
- ✅ **Network ACLs**: Gratis

---

## 📈 Totales por Categoría

| Categoría | Costo Mensual |
|-----------|---------------|
| **Compute (EC2)** | $30.63 |
| **Almacenamiento (EBS)** | $14.32 |
| **S3** | $8.85 |
| **Networking** | $61-66 |
| **Seguridad (WAF)** | $7.00 |
| **Contenedores (ECR)** | $1.10 |
| **Base de Datos (RDS)** | $68.44 |
| **Backend Terraform** | $0.28 |
| **TOTAL** | **$191-196 USD/mes** |

---

## 💡 Optimizaciones y Ahorros Potenciales

### Con Savings Plans (1 año, compromiso parcial)
- **EC2**: -20% = **-$6.13/mes**
- **RDS**: -20% = **-$9.93/mes**
- **Ahorro total**: **-$16.06/mes**
- **Nuevo total**: **$175-180 USD/mes**

### Con Reserved Instances (1 año, todo upfront)
- **EC2**: -40% = **-$12.25/mes**
- **RDS**: -40% = **-$19.86/mes**
- **Ahorro total**: **-$32.11/mes**
- **Nuevo total**: **$159-164 USD/mes**

### Otras Optimizaciones
1. **Deshabilitar NAT Gateway** si no se necesita acceso saliente: **-$35.10/mes**
2. **Reducir almacenamiento S3** (menos datos en Glacier): **-$2-4/mes**
3. **Deshabilitar Performance Insights** si no se usa: Ya está en $0
4. **Reducir retención de backups RDS** (7→3 días): **-$1.20/mes**

---

## 📊 Escenarios de Costo

### Escenario 1: Configuración Completa (Actual)
- **Todos los servicios habilitados**
- **Costo**: **$191-196 USD/mes**

### Escenario 2: Sin NAT Gateway
- **Sin acceso saliente a internet desde EC2**
- **Costo**: **$156-161 USD/mes** (-$35.10)

### Escenario 3: Sin RDS
- **Sin base de datos**
- **Costo**: **$123-128 USD/mes** (-$68.44)

### Escenario 4: Mínimo (Solo EC2 + EBS + S3 básico)
- **Sin ALB, CloudFront, WAF, NAT, RDS**
- **Costo**: **$54-59 USD/mes**

---

## ⚠️ Notas Importantes

1. **Precios variables**: Los precios pueden variar según:
   - Región específica (mx-central-1)
   - Cambios en precios de AWS
   - Uso real vs. estimado

2. **Transferencia de datos**: Los costos de transferencia pueden aumentar significativamente con alto tráfico

3. **LCU del ALB**: Depende del tráfico real (requests, conexiones, bytes procesados)

4. **Snapshots**: El costo real depende del tamaño incremental de los snapshots

5. **Backups RDS**: El costo incluye almacenamiento de backups por 7 días

6. **Monitoreo**: Considera usar AWS Cost Explorer para monitoreo en tiempo real

---

## 🔍 Cómo Verificar Costos Reales

1. **AWS Cost Explorer**: Dashboard de costos en tiempo real
2. **AWS Budgets**: Alertas cuando se exceden presupuestos
3. **AWS Cost Anomaly Detection**: Detecta costos inusuales
4. **Billing Dashboard**: Resumen mensual de facturación

---

## 📅 Actualización

**Última actualización**: Enero 2025  
**Región**: mx-central-1 (México Central)  
**Moneda**: USD

---

*Nota: Esta estimación es aproximada. Los costos reales pueden variar según el uso real de los servicios.*

