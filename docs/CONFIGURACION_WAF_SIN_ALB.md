# Configuración: WAF sin ALB

## ✅ Respuesta Directa

**Sí, puedes configurar WAF sin ALB.** WAF se asocia directamente a CloudFront, no necesita ALB.

## 🔧 Configuraciones Posibles

### Opción 1: CloudFront + WAF → EC2 Directo (Subnet Pública)

**Configuración:**
```hcl
enable_alb = false
ec2_subnet_tier = "public"
enable_cloudfront = true
enable_waf = true
```

**Arquitectura:**
```
Internet → CloudFront + WAF → EC2 (subnet pública)
```

**Costo:** ~$11-15 USD/mes (sin ALB)

### Opción 2: CloudFront + WAF → S3 (Contenido Estático)

**Configuración:**
```hcl
enable_alb = false
cloudfront_origin_s3_bucket = "mi-bucket-s3"
enable_cloudfront = true
enable_waf = true
```

**Arquitectura:**
```
Internet → CloudFront + WAF → S3 Bucket
```

**Costo:** ~$6-10 USD/mes

### Opción 3: CloudFront + WAF → ALB (Actual - Recomendada)

**Configuración:**
```hcl
enable_alb = true
ec2_subnet_tier = "private"
enable_cloudfront = true
enable_waf = true
```

**Arquitectura:**
```
Internet → CloudFront + WAF → ALB → EC2 (subnet privada)
```

**Costo:** ~$27-35 USD/mes

## ⚠️ Limitaciones

### Si EC2 está en Subnet Privada:
- ❌ **NO puedes** usar CloudFront → EC2 directo
- ✅ **DEBES** usar ALB o mover EC2 a subnet pública

### Si EC2 está en Subnet Pública:
- ✅ **PUEDES** usar CloudFront → EC2 directo (sin ALB)
- ⚠️ **Considera** seguridad: EC2 expuesto directamente

## 📝 Variables Configuradas

### `enable_alb` (default: true)
- `true`: Usa ALB como origen de CloudFront
- `false`: CloudFront apunta directamente a EC2 (si está en subnet pública) o S3

### `cloudfront_origin_s3_bucket` (default: "")
- Si se especifica, CloudFront apunta a S3 en lugar de ALB/EC2
- Útil para contenido estático

### `ec2_subnet_tier` (default: "private")
- `"private"`: EC2 en subnet privada (requiere ALB para CloudFront)
- `"public"`: EC2 en subnet pública (puede usar CloudFront directo)

## 🚀 Ejemplo: WAF sin ALB

### Escenario: EC2 en Subnet Pública

```hcl
# En terraform.tfvars o variables
enable_alb = false
ec2_subnet_tier = "public"
enable_cloudfront = true
enable_waf = true
```

**Resultado:**
- ✅ CloudFront + WAF → EC2 directo
- ✅ Sin ALB (ahorro de ~$16-20/mes)
- ⚠️ EC2 expuesto directamente (menos seguro)

## 💡 Recomendación

### Para Producción:
**Usa ALB** (`enable_alb = true`) porque:
- ✅ Alta disponibilidad
- ✅ Health checks automáticos
- ✅ Escalado horizontal fácil
- ✅ EC2 en subnet privada (más seguro)
- ✅ Load balancing

### Para Desarrollo/Pruebas:
**Puedes omitir ALB** (`enable_alb = false`) si:
- ✅ EC2 está en subnet pública
- ✅ No necesitas alta disponibilidad
- ✅ Quieres ahorrar costos

## ✅ Conclusión

**WAF funciona perfectamente sin ALB.** El ALB solo es necesario si:
1. EC2 está en subnet privada (tu caso actual)
2. Necesitas alta disponibilidad
3. Necesitas load balancing

Si mueves EC2 a subnet pública, puedes usar CloudFront + WAF directamente sin ALB.

