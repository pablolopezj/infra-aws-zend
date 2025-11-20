#!/bin/bash

# Script para actualizar ~/.ssh/config con las IPs actuales del proyecto

echo "=== Actualizando configuración SSH ==="

cd envs/prod

# Obtener IPs
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip 2>/dev/null)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" = "null" ]; then
  echo "❌ ERROR: No se pudo obtener la IP del bastion"
  exit 1
fi

if [ -z "$PRIVATE_IP" ] || [ "$PRIVATE_IP" = "null" ]; then
  echo "❌ ERROR: No se pudo obtener la IP privada de la instancia"
  exit 1
fi

echo "Bastion IP: $BASTION_IP"
echo "Private IP: $PRIVATE_IP"

# Backup del archivo config
SSH_CONFIG="$HOME/.ssh/config"
if [ -f "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
  echo "✅ Backup creado: $SSH_CONFIG.backup.*"
fi

# Crear o actualizar configuración
if [ ! -f "$SSH_CONFIG" ]; then
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
fi

# Eliminar configuración antigua si existe
sed -i.bak '/^# Bastion Host Zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null || \
sed -i '' '/^# Bastion Host Zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null

# Agregar nueva configuración
cat >> "$SSH_CONFIG" << EOF

# Bastion Host Zend
Host bastion-zend
    HostName $BASTION_IP
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ForwardAgent yes

# Instancia Privada Zend (a través del bastion)
Host zend-app
    HostName $PRIVATE_IP
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    ProxyJump bastion-zend
    ProxyCommand ssh -W %h:%p bastion-zend
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

echo ""
echo "✅ Configuración SSH actualizada"
echo ""
echo "Ahora puedes usar:"
echo "  ssh bastion-zend    # Conectarse al bastion"
echo "  ssh zend-app        # Conectarse a la instancia privada (a través del bastion)"
echo ""

