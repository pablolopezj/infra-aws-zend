#!/bin/bash

# Script de diagnóstico para conexión SSH al Bastion

echo "=== Diagnóstico de Conexión SSH al Bastion ==="
echo ""

cd envs/prod

# 1. Verificar que Terraform está inicializado
if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -d ".terraform" ]; then
  echo "❌ ERROR: Terraform no está inicializado"
  echo "Ejecuta: terraform init"
  exit 1
fi

# 2. Verificar que el bastion existe
INSTANCE_ID=$(terraform output -raw bastion_instance_id 2>/dev/null)
if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "null" ]; then
  echo "❌ ERROR: Bastion no existe o no se ha creado"
  echo "Ejecuta: terraform apply"
  exit 1
fi

echo "✅ Bastion ID: $INSTANCE_ID"

# 3. Verificar estado de la instancia
echo ""
echo "=== Estado de la Instancia ==="
STATE=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text 2>/dev/null)

if [ -z "$STATE" ]; then
  echo "❌ ERROR: No se pudo obtener el estado. Verifica tus credenciales AWS"
  exit 1
fi

echo "Estado: $STATE"

if [ "$STATE" != "running" ]; then
  echo "⚠️  ADVERTENCIA: Bastion no está corriendo. Estado: $STATE"
  if [ "$STATE" = "stopped" ]; then
    echo "Iniciando instancia..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region mx-central-1
    echo "Esperando a que la instancia inicie..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region mx-central-1
    echo "✅ Instancia iniciada"
  fi
fi

# 4. Verificar IP Pública
echo ""
echo "=== IP Pública ==="
PUBLIC_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
  # Intentar obtener desde AWS directamente
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region mx-central-1 \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null)
fi

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
  echo "❌ ERROR: Bastion no tiene IP pública"
  echo "Verifica que esté en subnet pública y que tenga auto-assign IP habilitado"
  exit 1
fi

echo "IP Pública: $PUBLIC_IP"

# 5. Verificar Security Group
echo ""
echo "=== Security Group ==="
SG_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "Security Group ID: $SG_ID"

# Verificar regla SSH
SSH_RULES=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' \
  --output json)

if [ "$SSH_RULES" = "[]" ] || [ -z "$SSH_RULES" ] || [ "$SSH_RULES" = "null" ]; then
  echo "❌ ERROR: Security Group no tiene regla SSH (puerto 22)"
  echo ""
  echo "Agregando regla SSH..."
  MY_IP=$(curl -s ifconfig.me 2>/dev/null || echo "0.0.0.0")
  echo "Tu IP: $MY_IP"
  
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region mx-central-1 2>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "✅ Regla SSH agregada (permite desde cualquier IP)"
  else
    echo "⚠️  La regla puede que ya exista o hubo un error"
  fi
else
  echo "✅ Security Group tiene regla SSH"
  echo "Reglas SSH:"
  echo "$SSH_RULES" | jq -r '.[] | "  - Puerto: \(.FromPort), CIDR: \(.IpRanges[0].CidrIp // "N/A")"'
fi

# 6. Verificar Key Pair
echo ""
echo "=== Key Pair ==="
KEY_NAME=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].KeyName' \
  --output text)

echo "Key Pair en AWS: $KEY_NAME"

# Verificar si existe en AWS
KEY_EXISTS=$(aws ec2 describe-key-pairs \
  --key-names "$KEY_NAME" \
  --region mx-central-1 \
  --query 'KeyPairs[0].KeyName' \
  --output text 2>/dev/null)

if [ -z "$KEY_EXISTS" ] || [ "$KEY_EXISTS" = "None" ]; then
  echo "⚠️  ADVERTENCIA: Key pair '$KEY_NAME' no existe en AWS"
  echo "Crea el key pair primero o verifica el nombre"
else
  echo "✅ Key pair existe en AWS"
fi

# 7. Verificar archivo de clave local
echo ""
echo "=== Archivo de Clave Local ==="
KEY_FILE=""

# Buscar diferentes variantes del nombre
if [ -f ~/.ssh/zend-app-key.pem ]; then
  KEY_FILE=~/.ssh/zend-app-key.pem
elif [ -f ~/.ssh/zend-app-key ]; then
  KEY_FILE=~/.ssh/zend-app-key
else
  echo "❌ ERROR: Archivo de clave no encontrado"
  echo "Busca en: ~/.ssh/zend-app-key.pem o ~/.ssh/zend-app-key"
  exit 1
fi

echo "✅ Archivo encontrado: $KEY_FILE"

# Verificar permisos
PERMS=$(stat -f "%OLp" "$KEY_FILE" 2>/dev/null || stat -c "%a" "$KEY_FILE" 2>/dev/null)
if [ "$PERMS" != "400" ] && [ "$PERMS" != "600" ]; then
  echo "⚠️  ADVERTENCIA: Permisos actuales: $PERMS (deben ser 400)"
  echo "Ejecutando: chmod 400 $KEY_FILE"
  chmod 400 "$KEY_FILE"
  echo "✅ Permisos actualizados"
else
  echo "✅ Permisos correctos: $PERMS"
fi

# 8. Verificar conectividad de red
echo ""
echo "=== Prueba de Conectividad ==="
echo "Probando conexión a puerto 22..."

if command -v nc &> /dev/null; then
  timeout 5 nc -zv $PUBLIC_IP 22 2>&1 | head -1
  if [ $? -eq 0 ]; then
    echo "✅ Puerto 22 está abierto y accesible"
  else
    echo "❌ ERROR: No se puede conectar al puerto 22"
    echo "Posibles causas:"
    echo "  - Security Group bloquea el acceso"
    echo "  - Firewall local bloquea el puerto"
    echo "  - La instancia no está completamente iniciada"
  fi
else
  echo "⚠️  'nc' no está instalado, saltando prueba de conectividad"
fi

# 9. Comando final
echo ""
echo "=== Comando para Conectarse ==="
echo "Ejecuta este comando para conectarte:"
echo ""
echo "  ssh -i $KEY_FILE ec2-user@$PUBLIC_IP"
echo ""
echo "O con verbose mode para ver detalles:"
echo ""
echo "  ssh -v -i $KEY_FILE ec2-user@$PUBLIC_IP"
echo ""

# 10. Si todo está bien, intentar conexión de prueba
echo "=== Intentando Conexión de Prueba ==="
echo "Probando conexión (timeout 10 segundos)..."
echo ""

timeout 10 ssh -i "$KEY_FILE" \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ec2-user@$PUBLIC_IP \
    "echo '✅ Conexión exitosa!'" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "✅✅✅ ¡Conexión exitosa! El bastion está funcionando correctamente."
elif [ $EXIT_CODE -eq 124 ]; then
  echo ""
  echo "⏱️  Timeout: La conexión está tardando mucho"
  echo "Posibles causas:"
  echo "  - Security Group no permite tu IP"
  echo "  - La instancia aún se está iniciando"
  echo "  - Problema de red/firewall"
elif [ $EXIT_CODE -eq 255 ]; then
  echo ""
  echo "❌ Error de autenticación"
  echo "Posibles causas:"
  echo "  - Key pair no coincide"
  echo "  - Usuario incorrecto (debe ser 'ec2-user' para Amazon Linux)"
else
  echo ""
  echo "❌ Error de conexión (código: $EXIT_CODE)"
fi

echo ""
echo "=== Fin del Diagnóstico ==="

