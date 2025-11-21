# Análisis de Especificaciones: CloudFront + WAF

## 📊 Especificaciones Propuestas

### CloudFront
- **Transferencia de datos saliente a Internet**: 50 GB/mes
- **Solicitudes HTTPS**: 1,000,000/mes
- **Transferencia de datos saliente al origen**: 5 GB/mes

### WAF
- **Web ACLs**: 1 por mes
- **Reglas por ACL**: 3 por mes
- **Grupos de reglas administrados**: 1 por mes

## ✅ Análisis de Validez

### CloudFront - ✅ CORRECTO

**Transferencia de datos saliente (50 GB/mes):**
- ✅ **Adecuado** para una aplicación web pequeña/mediana
- ✅ **Costo estimado**: ~$4.25/mes (50 GB × $0.085/GB)
- ✅ **Escalable**: Puedes aumentar según necesidad

**Solicitudes HTTPS (1,000,000/mes):**
- ✅ **Adecuado** para ~33,000 requests/día o ~1,400 requests/hora
- ✅ **Costo**: Incluido en transferencia de datos
- ✅ **Razonable** para inicio de producción

**Transferencia al origen (5 GB/mes):**
- ✅ **Adecuado** si CloudFront cachea bien el contenido
- ✅ **Costo estimado**: ~$0.50/mes (5 GB × $0.10/GB)
- ✅ **Indica buen uso de caché**: Solo 10% del tráfico va al origen

**Recomendación**: ✅ **Las especificaciones son correctas y adecuadas**

### WAF - ✅ CORRECTO con Ajustes Recomendados

**1 Web ACL:**
- ✅ **Correcto**: Una ACL es suficiente para una aplicación
- ✅ **Costo**: $5 USD/mes base

**3 Reglas por ACL:**
- ✅ **Correcto**: Configuración inicial adecuada
- ✅ **Recomendación**: Usar reglas administradas por AWS (más eficientes)
- ✅ **Costo**: $1 USD/mes por cada 1M requests procesados

**1 Grupo de reglas administrado:**
- ✅ **Correcto**: Usar grupos de reglas AWS Managed Rules
- ✅ **Recomendación**: Usar al menos 2 grupos:
  - `AWSManagedRulesCommonRuleSet` (OWASP Top 10)
  - `AWSManagedRulesKnownBadInputsRuleSet`
- ✅ **Costo**: Incluido en el costo de reglas

**Costo total WAF estimado**: ~$6-10 USD/mes

## 🔧 Ajustes Recomendados

### 1. CloudFront - Optimizaciones

**Price Class:**
- ✅ Usar `PriceClass_100` (solo US, Canada, Europa) para reducir costos
- ✅ Cambiar a `PriceClass_All` solo si necesitas cobertura global

**Caché:**
- ✅ Configurar `Cache-Control` headers en tu aplicación
- ✅ Usar `CachingOptimized` policy para mejor rendimiento
- ✅ Configurar TTL adecuado según tipo de contenido

**Compresión:**
- ✅ Habilitar compresión automática (reduce transferencia)

### 2. WAF - Reglas Recomendadas

**Reglas Mínimas (3 reglas):**
1. ✅ **AWSManagedRulesCommonRuleSet** (OWASP Top 10)
2. ✅ **AWSManagedRulesKnownBadInputsRuleSet** (SQL injection, XSS)
3. ✅ **Rate Limiting** (opcional, pero recomendado)

**Grupos de Reglas Adicionales (Opcionales):**
- `AWSManagedRulesLinuxRuleSet` (si usas Linux)
- `AWSManagedRulesUnixRuleSet` (si usas Unix)
- `AWSManagedRulesWordPressRuleSet` (si usas WordPress)

### 3. Arquitectura - Consideración Importante

**⚠️ PROBLEMA IDENTIFICADO:**
Tu EC2 está en una **subnet privada** sin acceso público directo.

**Soluciones:**

**Opción A: CloudFront → ALB → EC2 (Recomendada)**
```
Internet → CloudFront + WAF → ALB (subnet pública) → EC2 (subnet privada)
```
- ✅ Alta disponibilidad
- ✅ Health checks automáticos
- ✅ Escalado horizontal fácil
- ❌ Costo adicional: ~$16-20/mes ALB

**Opción B: CloudFront → EC2 Directo (No recomendada)**
```
Internet → CloudFront + WAF → EC2 (subnet privada)
```
- ❌ Requiere IP pública o NAT Gateway
- ❌ No hay alta disponibilidad
- ❌ No hay health checks

**Recomendación**: Implementar **Opción A** (CloudFront + ALB)

## 💰 Estimación de Costos Totales

| Componente | Costo Mensual |
|------------|---------------|
| CloudFront (50 GB) | ~$4.25 |
| CloudFront (5 GB origen) | ~$0.50 |
| WAF (base + requests) | ~$6-10 |
| **Total CloudFront + WAF** | **~$11-15 USD/mes** |
| ALB (si se agrega) | ~$16-20 USD/mes |
| **Total con ALB** | **~$27-35 USD/mes** |

## ✅ Conclusión

**Las especificaciones son CORRECTAS y ADECUADAS** para una aplicación web en producción inicial.

**Ajustes recomendados:**
1. ✅ Agregar ALB entre CloudFront y EC2 (para alta disponibilidad)
2. ✅ Usar 2-3 grupos de reglas WAF administradas por AWS
3. ✅ Configurar compresión y caché en CloudFront
4. ✅ Monitorear métricas para ajustar según necesidad

**Próximos pasos:**
1. Crear módulo ALB (si no existe)
2. Integrar CloudFront + WAF + ALB
3. Configurar health checks
4. Probar y monitorear

