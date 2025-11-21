# CloudFront + WAF sin ALB - Opciones

## ✅ Sí, es posible usar WAF sin ALB

**WAF se asocia directamente a CloudFront**, no necesita ALB. El ALB solo es necesario si CloudFront necesita un origen accesible.

## 🔄 Opciones de Arquitectura

### Opción 1: CloudFront + WAF → EC2 Directo (Subnet Pública)
```
Internet → CloudFront + WAF → EC2 (subnet pública con IP pública)
```

**Requisitos:**
- EC2 debe estar en subnet pública
- EC2 debe tener IP pública o Elastic IP
- Security Group debe permitir tráfico desde CloudFront

**Ventajas:**
- ✅ Sin costo de ALB (~$16-20/mes ahorrados)
- ✅ Menor latencia (menos saltos)
- ✅ Más simple

**Desventajas:**
- ❌ EC2 expuesto directamente (menos seguro)
- ❌ Sin alta disponibilidad (una sola instancia)
- ❌ Sin health checks automáticos
- ❌ Sin load balancing

**Costo:** ~$11-15 USD/mes (solo CloudFront + WAF)

### Opción 2: CloudFront + WAF → S3 (Contenido Estático)
```
Internet → CloudFront + WAF → S3 Bucket
```

**Requisitos:**
- Contenido estático (HTML, CSS, JS, imágenes)
- S3 bucket configurado como sitio web

**Ventajas:**
- ✅ Sin servidores que gestionar
- ✅ Altamente escalable
- ✅ Muy económico
- ✅ Sin ALB necesario

**Desventajas:**
- ❌ Solo contenido estático
- ❌ No aplicaciones dinámicas

**Costo:** ~$6-10 USD/mes (CloudFront + WAF + S3)

### Opción 3: CloudFront + WAF → API Gateway → Lambda
```
Internet → CloudFront + WAF → API Gateway → Lambda
```

**Requisitos:**
- Aplicación serverless
- API Gateway configurado

**Ventajas:**
- ✅ Sin servidores
- ✅ Escalado automático
- ✅ Pay-per-use

**Desventajas:**
- ❌ Requiere reescribir aplicación
- ❌ Cold starts en Lambda

**Costo:** Variable según uso

### Opción 4: CloudFront + WAF → EC2 (Subnet Privada con NAT)
```
Internet → CloudFront + WAF → EC2 (subnet privada)
```

**⚠️ NO FUNCIONA**: CloudFront no puede acceder directamente a instancias en subnet privada sin IP pública.

**Solución:** Necesitas ALB o mover EC2 a subnet pública.

## 💡 Recomendación para tu Caso

### Si EC2 está en Subnet Privada (tu caso actual):
**Opción A: Mantener ALB** (Recomendada)
- ✅ Alta disponibilidad
- ✅ Health checks
- ✅ Escalado horizontal
- ✅ Seguridad (EC2 en subnet privada)

**Opción B: Mover EC2 a Subnet Pública**
- ✅ Sin ALB (ahorro de ~$16-20/mes)
- ❌ Menos seguro
- ❌ Sin alta disponibilidad

### Si EC2 está en Subnet Pública:
**CloudFront + WAF → EC2 Directo**
- ✅ Sin ALB necesario
- ✅ Menor costo
- ✅ Menor latencia

## 🔧 Implementación

Puedo modificar la configuración para:
1. Hacer ALB opcional
2. Permitir CloudFront apuntar directamente a EC2 si está en subnet pública
3. Mantener WAF asociado a CloudFront (sin cambios)

¿Quieres que implemente alguna de estas opciones?

