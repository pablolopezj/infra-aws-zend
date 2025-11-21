# Riesgos de Mover EC2 a Subnet Pública (Sin ALB)

## ⚠️ Resumen Ejecutivo

**Mover EC2 a subnet pública y eliminar ALB expone tu aplicación a riesgos significativos de seguridad, disponibilidad y escalabilidad.**

**Recomendación: NO hacerlo en producción sin mitigaciones adecuadas.**

---

## 🔴 Riesgos Críticos de Seguridad

### 1. Exposición Directa a Internet

**Riesgo:**
- EC2 tiene IP pública directamente accesible desde Internet
- No hay capa intermedia (ALB) que filtre o proteja el tráfico
- El servidor está "en primera línea" de defensa

**Impacto:**
- ✅ **ALTO**: Ataques DDoS afectan directamente al servidor
- ✅ **ALTO**: Vulnerabilidades en la aplicación son explotables directamente
- ✅ **ALTO**: Escaneo de puertos y servicios expuestos
- ✅ **ALTO**: Ataques de fuerza bruta más efectivos

**Ejemplo:**
```
Sin ALB: Internet → EC2 (IP pública expuesta)
Con ALB: Internet → ALB (filtra) → EC2 (IP privada oculta)
```

### 2. Pérdida de Protección de WAF en Capa de Aplicación

**Riesgo:**
- WAF está asociado a CloudFront, no directamente a EC2
- Si CloudFront apunta directamente a EC2, WAF sigue funcionando
- **PERO**: Si alguien accede directamente a la IP pública de EC2, bypasea CloudFront y WAF

**Impacto:**
- ✅ **MEDIO-ALTO**: Ataques directos a EC2 ignoran WAF
- ✅ **MEDIO**: Necesitas configurar Security Groups más restrictivos
- ✅ **MEDIO**: Debes bloquear acceso directo a EC2 (solo permitir CloudFront)

**Mitigación Parcial:**
- Configurar Security Group para solo permitir tráfico desde CloudFront IPs
- Usar AWS WAF en Security Group (limitado)
- Bloquear acceso directo a puertos no necesarios

### 3. Exposición de Información del Sistema

**Riesgo:**
- Headers HTTP pueden revelar información del servidor (versión, OS, etc.)
- Logs de acceso pueden exponer rutas internas
- Errores pueden revelar información sensible

**Impacto:**
- ✅ **MEDIO**: Información útil para atacantes
- ✅ **MEDIO**: Facilita ataques dirigidos

**Con ALB:**
- ALB puede modificar/eliminar headers sensibles
- Errores pueden ser manejados de forma genérica

### 4. Ataques de Fuerza Bruta

**Riesgo:**
- Si hay servicios expuestos (SSH, RDP, etc.), son accesibles directamente
- Ataques de fuerza bruta son más efectivos

**Impacto:**
- ✅ **ALTO**: Si SSH está expuesto (aunque no debería estar)
- ✅ **MEDIO**: Si hay otros servicios expuestos

**Mitigación:**
- Usar Security Groups restrictivos
- Usar bastion host (ya lo tienes)
- Deshabilitar acceso SSH desde Internet

---

## 🟡 Riesgos de Disponibilidad

### 1. Sin Alta Disponibilidad

**Riesgo:**
- Una sola instancia EC2
- Si falla, la aplicación queda completamente inaccesible
- No hay redundancia ni failover automático

**Impacto:**
- ✅ **ALTO**: Downtime completo si EC2 falla
- ✅ **ALTO**: Sin recuperación automática
- ✅ **MEDIO**: Necesitas monitoreo y respuesta manual

**Con ALB:**
- Puedes tener múltiples instancias EC2
- ALB distribuye carga y hace health checks
- Si una instancia falla, ALB redirige a otras

**Ejemplo:**
```
Sin ALB: EC2 falla → Aplicación caída (100% downtime)
Con ALB: EC2-1 falla → ALB redirige a EC2-2 (0% downtime)
```

### 2. Sin Health Checks Automáticos

**Riesgo:**
- No hay verificación automática de que la aplicación funciona
- Si la aplicación se corrompe pero el servidor sigue activo, no hay detección

**Impacto:**
- ✅ **MEDIO**: Errores de aplicación pueden pasar desapercibidos
- ✅ **MEDIO**: Necesitas monitoreo externo (CloudWatch, etc.)

**Con ALB:**
- Health checks automáticos cada 30 segundos
- Si la aplicación no responde, ALB marca la instancia como no saludable
- Puede activar Auto Scaling para reemplazar instancias

### 3. Sin Load Balancing

**Riesgo:**
- Todo el tráfico va a una sola instancia
- Picos de tráfico pueden saturar el servidor
- No hay distribución de carga

**Impacto:**
- ✅ **MEDIO**: Limitaciones de escalado
- ✅ **MEDIO**: Posible degradación de rendimiento en picos
- ✅ **BAJO**: Si el tráfico es predecible y bajo

**Con ALB:**
- Distribución de carga entre múltiples instancias
- Escalado horizontal fácil
- Mejor rendimiento bajo carga

---

## 🟠 Riesgos Operacionales

### 1. Gestión de IPs Públicas

**Riesgo:**
- EC2 obtiene IP pública dinámica (a menos que uses Elastic IP)
- Si la instancia se reinicia, puede cambiar la IP
- CloudFront necesita actualizar el origen

**Impacto:**
- ✅ **MEDIO**: Necesitas Elastic IP (costo adicional si no está en uso)
- ✅ **BAJO**: Si usas Elastic IP, el riesgo es mínimo

**Mitigación:**
- Usar Elastic IP asociada a la instancia
- Actualizar CloudFront si cambia la IP

### 2. Configuración de Security Groups Más Compleja

**Riesgo:**
- Debes configurar Security Groups para:
  - Permitir tráfico solo desde CloudFront
  - Bloquear acceso directo desde Internet
  - Permitir acceso desde bastion (SSH)

**Impacto:**
- ✅ **BAJO-MEDIO**: Configuración más compleja
- ✅ **BAJO**: Riesgo de error de configuración

**Configuración Necesaria:**
```hcl
# Security Group para EC2 en subnet pública
ingress {
  description = "HTTP from CloudFront only"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["CloudFront IP ranges"] # Lista de IPs de CloudFront
}

ingress {
  description = "HTTPS from CloudFront only"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["CloudFront IP ranges"]
}

# NO permitir SSH desde Internet (solo desde bastion)
ingress {
  description = "SSH from bastion only"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_groups = [bastion_security_group_id]
}
```

### 3. Monitoreo y Logging

**Riesgo:**
- Necesitas configurar CloudWatch más detallado
- Logs de acceso deben ser gestionados en EC2
- Sin logs de ALB (que son útiles para análisis)

**Impacto:**
- ✅ **BAJO**: Más trabajo de configuración
- ✅ **BAJO**: Menos visibilidad comparado con ALB logs

---

## 🟢 Riesgos Menores

### 1. Costo de Elastic IP

**Riesgo:**
- Si no usas Elastic IP, la IP puede cambiar
- Elastic IP cuesta $0.00 si está asociada, pero $0.005/hora si no está en uso

**Impacto:**
- ✅ **BAJO**: Solo si no gestionas bien las IPs

### 2. SSL/TLS Termination

**Riesgo:**
- SSL/TLS debe ser gestionado en EC2 (no en ALB)
- Necesitas certificados en el servidor
- Renovación de certificados más compleja

**Impacto:**
- ✅ **BAJO**: Si usas CloudFront, SSL/TLS se termina ahí
- ✅ **BAJO**: Solo afecta si quieres HTTPS directo a EC2

---

## 📊 Comparación: Con ALB vs Sin ALB

| Aspecto | Con ALB | Sin ALB (Subnet Pública) |
|---------|---------|--------------------------|
| **Seguridad** | ✅ Alta (EC2 oculto) | ⚠️ Media (EC2 expuesto) |
| **Alta Disponibilidad** | ✅ Múltiples instancias | ❌ Una sola instancia |
| **Health Checks** | ✅ Automáticos | ❌ Manuales |
| **Load Balancing** | ✅ Sí | ❌ No |
| **Escalabilidad** | ✅ Horizontal fácil | ❌ Limitada |
| **Costo** | ❌ +$30/mes | ✅ Ahorro $30/mes |
| **Complejidad** | ✅ Menor | ⚠️ Mayor (Security Groups) |
| **WAF Protection** | ✅ Completa | ⚠️ Parcial (solo vía CloudFront) |
| **DDoS Protection** | ✅ ALB + CloudFront | ⚠️ Solo CloudFront |

---

## 🛡️ Mitigaciones Si Decides Hacerlo

### 1. Security Groups Muy Restrictivos

```hcl
# Solo permitir tráfico desde CloudFront
# Obtener rangos de IP de CloudFront de AWS
data "aws_ip_ranges" "cloudfront" {
  regions  = ["global"]
  services = ["cloudfront"]
}

resource "aws_security_group_rule" "cloudfront_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = data.aws_ip_ranges.cloudfront.cidr_blocks
}
```

### 2. Usar CloudFront Siempre (Nunca Acceso Directo)

- Configurar CloudFront como único punto de entrada
- Bloquear acceso directo a EC2 desde Internet
- Usar custom headers para verificar que el tráfico viene de CloudFront

### 3. Monitoreo Intensivo

- CloudWatch Alarms para métricas críticas
- Alertas de seguridad (GuardDuty, Security Hub)
- Logs detallados de acceso

### 4. Auto Scaling Group (Aunque Sin ALB)

- Configurar Auto Scaling para reemplazar instancias fallidas
- Usar Application Load Balancer interno o Network Load Balancer
- O usar Route 53 health checks con failover

### 5. WAF Adicional en Security Group

- Usar AWS Network Firewall
- O configurar reglas de Security Group más estrictas

---

## ✅ Recomendación Final

### Para Producción:
**NO eliminar ALB** porque:
1. ✅ Seguridad: EC2 queda oculto en subnet privada
2. ✅ Alta disponibilidad: Múltiples instancias posibles
3. ✅ Escalabilidad: Load balancing automático
4. ✅ Health checks: Detección automática de problemas
5. ✅ WAF: Protección completa en todas las capas

**El ahorro de $30/mes NO justifica los riesgos en producción.**

### Para Desarrollo/Pruebas:
**Puede ser aceptable** si:
1. ✅ Es un ambiente temporal
2. ✅ No hay datos sensibles
3. ✅ El tráfico es mínimo
4. ✅ Implementas todas las mitigaciones

### Alternativa: Híbrida
**Mantener ALB pero optimizar costos:**
1. ✅ Usar ALB solo en producción
2. ✅ En desarrollo, usar EC2 directo
3. ✅ Usar Reserved Instances para ahorrar en EC2
4. ✅ Optimizar CloudFront para reducir transferencia

---

## 📝 Checklist de Riesgos

Si decides eliminar ALB, asegúrate de:

- [ ] Configurar Security Groups para solo permitir CloudFront
- [ ] Usar Elastic IP para IP estática
- [ ] Bloquear acceso SSH desde Internet (solo bastion)
- [ ] Configurar CloudWatch Alarms
- [ ] Implementar monitoreo de seguridad (GuardDuty)
- [ ] Documentar procedimientos de recuperación
- [ ] Tener plan de backup y restore
- [ ] Considerar Auto Scaling Group
- [ ] Revisar logs regularmente
- [ ] Tener plan de respuesta a incidentes

---

## 🎯 Conclusión

**Eliminar ALB y mover EC2 a subnet pública es una decisión de arquitectura que:**
- ✅ **Ahorra**: ~$30/mes
- ❌ **Expone**: Tu aplicación a riesgos significativos
- ❌ **Reduce**: Alta disponibilidad y escalabilidad
- ❌ **Complica**: Gestión de seguridad

**Recomendación: Mantener ALB en producción. El costo es justificado por la seguridad y disponibilidad que proporciona.**

