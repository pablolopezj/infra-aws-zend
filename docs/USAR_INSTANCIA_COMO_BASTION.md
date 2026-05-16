# Usar Instancia Existente como Bastion Host

## 🔍 Situación Actual

Tu instancia EC2 está configurada por defecto en **subnet privada** (`ec2_subnet_tier = "private"`).

## ⚠️ Problema

**Una instancia en subnet privada NO puede funcionar como bastion** porque:
- ❌ No tiene IP pública
- ❌ No es accesible desde Internet
- ❌ No puede recibir conexiones SSH desde fuera de la VPC

## ✅ Solución: Mover a Subnet Pública

Para que tu instancia funcione como bastion, necesitas:

### Opción 1: Cambiar la Instancia a Subnet Pública (Rápido)

```bash
cd envs/prod

# Cambiar a subnet pública
terraform apply -var="ec2_subnet_tier=public"
```

**Esto hará:**
- ✅ Mover la instancia a subnet pública
- ✅ Asignar IP pública
- ✅ Usar Security Group público
- ✅ Permitir acceso SSH desde Internet

### Opción 2: Actualizar el Default en Variables

Edita `envs/prod/variables.tf`:

```terraform
variable "ec2_subnet_tier" {
  default = "public"  # Cambiar de "private" a "public"
}
```

## ⚠️ Consideraciones Importantes

### 1. **Separación de Responsabilidades** (Mejores Prácticas)

**Problema**: Usar la misma instancia como servidor de aplicación Y bastion no es ideal porque:

- ⚠️ **Riesgo de seguridad**: Si el bastion es comprometido, tu aplicación también
- ⚠️ **Mantenimiento**: No puedes reiniciar/actualizar el bastion sin afectar la app
- ⚠️ **Auditoría**: Dificulta rastrear quién accedió al bastion vs a la app
- ⚠️ **Compliance**: Muchos estándares requieren separación

**Mejor práctica**: 
- Instancia dedicada como bastion (t3.micro o t4g.micro)
- Instancias de aplicación en subnet privada

### 2. **Security Group**

El Security Group público actualmente permite:
- HTTP (80) y HTTPS (443) desde cualquier lugar
- **NO tiene regla SSH (22)**

Necesitas agregar regla SSH al Security Group público.

### 3. **Costo**

- **t4g.medium como bastion**: ~$30-40/mes (sobredimensionado para bastion)
- **t3.micro como bastion**: ~$7-10/mes (tamaño adecuado)

## 🎯 Opciones Recomendadas

### Opción A: Usar Instancia Existente como Bastion (Rápido)

**Pros:**
- ✅ No requiere crear nueva instancia
- ✅ Funciona inmediatamente
- ✅ Sin costos adicionales

**Contras:**
- ❌ Mezcla responsabilidades (app + bastion)
- ❌ Sobredimensionado (t4g.medium es mucho para bastion)
- ❌ No es mejor práctica

**Cuándo usar:**
- Desarrollo/testing
- Prototipos
- Presupuesto muy limitado

### Opción B: Crear Bastion Dedicado (Recomendado)

**Pros:**
- ✅✅ Separación de responsabilidades
- ✅✅ Mejor seguridad
- ✅✅ Tamaño adecuado (t3.micro)
- ✅✅ Mejores prácticas

**Contras:**
- 💰 Costo adicional (~$7-10/mes)

**Cuándo usar:**
- Producción
- Múltiples instancias
- Compliance requirements

### Opción C: Híbrido

**Usar instancia existente como bastion temporalmente**, y luego crear bastion dedicado cuando:
- Tengas más instancias
- Necesites mejor seguridad
- Tengas presupuesto

## 🚀 Implementación: Usar Instancia Existente

Si decides usar tu instancia como bastion:

### Paso 1: Mover a Subnet Pública

```bash
cd envs/prod
terraform apply -var="ec2_subnet_tier=public"
```

### Paso 2: Agregar Regla SSH al Security Group Público

Necesitas actualizar el módulo network para permitir SSH. Te muestro cómo...

### Paso 3: Conectarse

```bash
# Obtener IP pública
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)

# Conectarse
ssh -i ~/.ssh/zend-app-key ec2-user@$PUBLIC_IP
```

## 🔧 Configuración Necesaria

### 1. Agregar Regla SSH al Security Group Público

El Security Group público actualmente solo permite HTTP/HTTPS. Necesitas agregar SSH.

**Opción A: Agregar variable para puertos SSH**

Puedo actualizar el módulo network para que acepte puertos SSH configurables.

**Opción B: Agregar regla manualmente en AWS Console**

1. Ve a EC2 → Security Groups
2. Selecciona el Security Group público
3. Agrega regla de entrada:
   - Tipo: SSH
   - Puerto: 22
   - Origen: Tu IP o 0.0.0.0/0 (menos seguro)

## 💡 Recomendación Final

### Para Desarrollo/Testing
✅ **Usa la instancia existente como bastion**
- Cambia a subnet pública
- Agrega regla SSH
- Funciona inmediatamente

### Para Producción
✅✅ **Crea bastion dedicado**
- Mejor seguridad
- Mejores prácticas
- Escalable

## 🎯 ¿Qué Prefieres?

1. **Usar instancia existente como bastion** (rápido, menos seguro)
2. **Crear bastion dedicado** (mejor práctica, costo adicional)
3. **Usar Systems Manager** (máxima seguridad, sin costos)

¿Cuál opción prefieres que implemente?

---

**Última actualización**: 2024

