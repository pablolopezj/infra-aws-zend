# Implicaciones de Cambiar la Zona de Disponibilidad (AZ)

## ✅ ¿Es Recomendable Cambiar de Zona?

**SÍ, es completamente recomendable y común** cambiar de zona cuando hay problemas de capacidad. AWS está diseñado para esto.

## 📋 Implicaciones del Cambio

### 1. **Recursos que se Recrean**
Cuando cambias la zona de disponibilidad de la subnet privada:

- ✅ **Subnet privada**: Se recrea en la nueva zona
- ✅ **Network ACL privado**: Se asocia a la nueva subnet
- ✅ **Route Table Association**: Se actualiza
- ⚠️ **NAT Gateway**: NO se mueve (está en subnet pública, no afectado)
- ⚠️ **VPC, Security Groups, Internet Gateway**: NO se afectan (son regionales)

### 2. **Recursos que NO se Afectan**
- ✅ **VPC**: Es regional, no cambia
- ✅ **Security Groups**: Son regionales, no cambian
- ✅ **Internet Gateway**: Es regional, no cambia
- ✅ **NAT Gateway**: Está en subnet pública, no se afecta
- ✅ **EC2 Instances**: Se recrean en la nueva subnet (si existen)
- ✅ **EBS Volumes**: Se pueden mover o recrear según configuración

### 3. **Ventajas de Cambiar de Zona**
- ✅ **Disponibilidad**: Puede tener capacidad disponible
- ✅ **Resiliencia**: Distribución en múltiples zonas mejora la alta disponibilidad
- ✅ **Sin costo adicional**: No hay costo por cambiar de zona
- ✅ **Rápido**: El cambio se completa en minutos

### 4. **Consideraciones**
- ⚠️ **Downtime**: Si hay instancias corriendo, habrá downtime durante la recreación
- ⚠️ **IPs cambian**: Las IPs privadas cambiarán (pero esto es normal)
- ⚠️ **Estado de Terraform**: Necesitas aplicar los cambios con `terraform apply`

## 🔄 Proceso de Cambio

### Opción 1: Cambiar a mx-central-1c (Recomendado si mx-central-1a no tiene capacidad)

```bash
cd envs/prod

# Editar terraform.tfvars
private_subnet_az = "mx-central-1c"

# Aplicar cambios
terraform apply -var="private_subnet_az=mx-central-1c"
```

### Opción 2: Cambiar tipo de instancia temporalmente

```bash
# Probar con t4g.small (más pequeño, más disponible)
terraform apply -var="ec2_instance_type=t4g.small"

# O t4g.large (más grande, puede tener capacidad)
terraform apply -var="ec2_instance_type=t4g.large"
```

## ⏰ ¿Cuándo Esperar vs Cambiar?

### **ESPERAR (15-30 minutos)** si:
- ✅ Es la primera vez que intentas crear la instancia
- ✅ No hay urgencia inmediata
- ✅ Prefieres mantener la configuración actual

### **CAMBIAR DE ZONA** si:
- ⚠️ Han pasado más de 30 minutos sin éxito
- ⚠️ Necesitas la instancia urgentemente
- ⚠️ Has intentado múltiples veces sin éxito

## 📊 Zonas Disponibles en mx-central-1

- **mx-central-1a**: Subnet pública actual, NAT Gateway
- **mx-central-1b**: Subnet pública B (para ALB)
- **mx-central-1c**: Opción para subnet privada (si 1a no tiene capacidad)

## ✅ Recomendación Final

**Para tu caso específico:**
1. **ESPERA 15-30 minutos** y reintenta
2. Si no funciona, **cambia a mx-central-1c**
3. El cambio es seguro y no afecta otros recursos críticos

