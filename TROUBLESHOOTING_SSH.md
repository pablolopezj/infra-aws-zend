# Troubleshooting: Problemas de Conexión SSH al Bastion

## 🔍 Problema 1: Archivo de Clave No Encontrado

### Error
```
Warning: Identity file /Users/pablo/.ssh/zend-app-key not accessible: No such file or directory.
```

### Solución
Tu archivo de clave se llama `zend-app-key.pem`, no `zend-app-key`.

**Usa el nombre correcto:**
```bash
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$BASTION_IP
```

**O crea un alias/symlink:**
```bash
ln -s ~/.ssh/zend-app-key.pem ~/.ssh/zend-app-key
```

---

## 🔍 Problema 2: Conexión SSH Tarda Mucho / No Se Establece

### Posibles Causas y Soluciones

### 1. Verificar que el Bastion Está Corriendo

```bash
cd envs/prod

# Verificar estado de la instancia
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw bastion_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].{State:State.Name,PublicIP:PublicIpAddress}'
```

**Debe mostrar:**
- `State`: `running`
- `PublicIP`: Una IP válida (no `null`)

**Si está `stopped`**, inícialo:
```bash
aws ec2 start-instances \
  --instance-ids $(terraform output -raw bastion_instance_id) \
  --region mx-central-1
```

### 2. Verificar Security Group del Bastion

El Security Group del bastion debe permitir SSH (puerto 22) desde tu IP.

```bash
# Obtener ID del Security Group del bastion
SG_ID=$(cd envs/prod && terraform output -raw bastion_security_group_id 2>/dev/null)

# Si no existe el output, obtenerlo manualmente
if [ -z "$SG_ID" ]; then
  INSTANCE_ID=$(cd envs/prod && terraform output -raw bastion_instance_id)
  SG_ID=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region mx-central-1 \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)
fi

# Ver reglas de entrada
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query 'SecurityGroups[0].IpPermissions'
```

**Debe tener una regla que permita:**
- Puerto: `22`
- Protocolo: `tcp`
- Origen: Tu IP o `0.0.0.0/0`

### 3. Verificar tu IP Pública

```bash
# Obtener tu IP pública
MY_IP=$(curl -s ifconfig.me)
echo "Tu IP: $MY_IP"

# Verificar que el Security Group permite tu IP
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`]"
```

### 4. Agregar Regla SSH Manualmente (Temporal)

Si el Security Group no tiene regla SSH, agrégalo temporalmente:

```bash
# Obtener tu IP
MY_IP=$(curl -s ifconfig.me)

# Agregar regla SSH
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr $MY_IP/32 \
  --region mx-central-1
```

### 5. Verificar que el Key Pair Existe en AWS

```bash
# Verificar key pair
aws ec2 describe-key-pairs \
  --key-names zend-app-key \
  --region mx-central-1
```

**Si no existe**, créalo:
```bash
# Crear key pair desde tu clave pública
aws ec2 import-key-pair \
  --key-name zend-app-key \
  --public-key-material fileb://~/.ssh/zend-app-key.pub \
  --region mx-central-1
```

### 6. Verificar Permisos del Archivo de Clave

```bash
# Los permisos deben ser 400
chmod 400 ~/.ssh/zend-app-key.pem

# Verificar
ls -la ~/.ssh/zend-app-key.pem
# Debe mostrar: -r--------
```

### 7. Probar Conexión con Verbose Mode

```bash
# Ver detalles de la conexión
ssh -v -i ~/.ssh/zend-app-key.pem ec2-user@$BASTION_IP
```

Esto mostrará dónde se está quedando la conexión:
- Si dice "Connection timeout" → Problema de Security Group o red
- Si dice "Permission denied" → Problema de key pair
- Si se queda en "Connecting to..." → Problema de red/firewall

### 8. Verificar que la Instancia Tiene IP Pública

```bash
# Verificar IP pública
BASTION_IP=$(cd envs/prod && terraform output -raw bastion_public_ip)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" = "null" ]; then
  echo "ERROR: El bastion no tiene IP pública"
  echo "Verifica que esté en subnet pública y que tenga Elastic IP o auto-assign IP"
fi
```

### 9. Verificar Route Table

```bash
# Verificar que la subnet pública tiene ruta a Internet Gateway
SUBNET_ID=$(cd envs/prod && terraform output -raw public_subnet_id)

aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --region mx-central-1 \
  --query 'RouteTables[0].Routes'
```

**Debe tener una ruta:**
- `Destination`: `0.0.0.0/0`
- `GatewayId`: ID del Internet Gateway

---

## 🔧 Solución Rápida: Verificar Todo

Ejecuta este script para verificar todo:

```bash
#!/bin/bash

cd envs/prod

echo "=== Verificando Bastion ==="

# 1. Estado de la instancia
INSTANCE_ID=$(terraform output -raw bastion_instance_id 2>/dev/null)
if [ -z "$INSTANCE_ID" ]; then
  echo "❌ ERROR: Bastion no existe. Ejecuta 'terraform apply' primero."
  exit 1
fi

STATE=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

echo "Estado: $STATE"

if [ "$STATE" != "running" ]; then
  echo "❌ ERROR: Bastion no está corriendo. Estado: $STATE"
  exit 1
fi

# 2. IP Pública
PUBLIC_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
  echo "❌ ERROR: Bastion no tiene IP pública"
  exit 1
fi

echo "IP Pública: $PUBLIC_IP"

# 3. Security Group
SG_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "Security Group: $SG_ID"

# 4. Verificar regla SSH
SSH_RULE=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' \
  --output json)

if [ "$SSH_RULE" = "[]" ] || [ -z "$SSH_RULE" ]; then
  echo "❌ ERROR: Security Group no tiene regla SSH (puerto 22)"
  echo "Agregando regla SSH..."
  
  MY_IP=$(curl -s ifconfig.me)
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region mx-central-1
  
  echo "✅ Regla SSH agregada"
else
  echo "✅ Security Group tiene regla SSH"
fi

# 5. Verificar key pair
KEY_NAME=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].KeyName' \
  --output text)

echo "Key Pair: $KEY_NAME"

# 6. Verificar archivo de clave
if [ ! -f ~/.ssh/zend-app-key.pem ]; then
  echo "❌ ERROR: Archivo de clave no encontrado: ~/.ssh/zend-app-key.pem"
  exit 1
fi

echo "✅ Archivo de clave encontrado"

# 7. Verificar permisos
PERMS=$(stat -f "%OLp" ~/.ssh/zend-app-key.pem 2>/dev/null || stat -c "%a" ~/.ssh/zend-app-key.pem 2>/dev/null)
if [ "$PERMS" != "400" ] && [ "$PERMS" != "600" ]; then
  echo "⚠️  ADVERTENCIA: Permisos del archivo deben ser 400. Actuales: $PERMS"
  echo "Ejecuta: chmod 400 ~/.ssh/zend-app-key.pem"
fi

echo ""
echo "=== Intentando Conexión ==="
echo "Comando: ssh -i ~/.ssh/zend-app-key.pem ec2-user@$PUBLIC_IP"
echo ""
echo "Si aún no funciona, ejecuta con verbose:"
echo "ssh -v -i ~/.ssh/zend-app-key.pem ec2-user@$PUBLIC_IP"
```

---

## 🚀 Comandos de Diagnóstico Rápido

```bash
cd envs/prod

# 1. Verificar que todo existe
terraform output

# 2. Verificar estado del bastion
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw bastion_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].{State:State.Name,PublicIP:PublicIpAddress,KeyName:KeyName}'

# 3. Verificar Security Group
INSTANCE_ID=$(terraform output -raw bastion_instance_id)
SG_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query 'SecurityGroups[0].IpPermissions'

# 4. Probar conexión con timeout
timeout 10 ssh -i ~/.ssh/zend-app-key.pem \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    ec2-user@$(terraform output -raw bastion_public_ip) \
    "echo 'Conexión exitosa'" || echo "Conexión falló"
```

---

## ✅ Checklist de Verificación

- [ ] Bastion está en estado `running`
- [ ] Bastion tiene IP pública (no `null`)
- [ ] Security Group del bastion permite SSH (puerto 22)
- [ ] Security Group permite tu IP o `0.0.0.0/0`
- [ ] Key pair existe en AWS y coincide con tu clave privada
- [ ] Archivo de clave existe: `~/.ssh/zend-app-key.pem`
- [ ] Permisos del archivo son 400: `chmod 400 ~/.ssh/zend-app-key.pem`
- [ ] Subnet pública tiene ruta a Internet Gateway
- [ ] No hay firewall bloqueando el puerto 22

---

**Última actualización**: 2024

