#!/bin/bash

# Script para limpiar y actualizar configuración SSH

echo "=== Limpiando y actualizando configuración SSH ==="

SSH_CONFIG="$HOME/.ssh/config"

# Crear backup
if [ -f "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
  echo "✅ Backup creado"
fi

# Eliminar todas las entradas relacionadas con zend
sed -i.bak '/^#.*Zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null || \
sed -i '' '/^#.*Zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null

# Eliminar entradas específicas
sed -i.bak '/^Host bastion-zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null || \
sed -i '' '/^Host bastion-zend/,/^Host /d' "$SSH_CONFIG" 2>/dev/null

sed -i.bak '/^Host zend-app/,/^Host /d' "$SSH_CONFIG" 2>/dev/null || \
sed -i '' '/^Host zend-app/,/^Host /d' "$SSH_CONFIG" 2>/dev/null

# Obtener IPs
cd envs/prod
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip 2>/dev/null)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" = "null" ]; then
  echo "❌ ERROR: No se pudo obtener la IP del bastion"
  exit 1
fi

if [ -z "$PRIVATE_IP" ] || [ "$PRIVATE_IP" = "null" ]; then
  echo "❌ ERROR: No se pudo obtener la IP privada"
  exit 1
fi

echo "Bastion IP: $BASTION_IP"
echo "Private IP: $PRIVATE_IP"

# Agregar configuración limpia
cat >> "$SSH_CONFIG" << EOF

# ========================================
# Bastion Host Zend
# ========================================
Host bastion-zend
    HostName $BASTION_IP
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# ========================================
# Instancia Privada Zend (a través del bastion)
# ========================================
Host zend-app
    HostName $PRIVATE_IP
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    ProxyCommand ssh -W %h:%p bastion-zend
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

echo ""
echo "✅ Configuración SSH limpiada y actualizada"
echo ""
echo "Ahora puedes usar:"
echo "  ssh bastion-zend    # Conectarse al bastion"
echo "  ssh zend-app        # Conectarse a la instancia privada (a través del bastion)"
echo ""

