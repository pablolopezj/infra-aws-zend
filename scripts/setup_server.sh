#!/bin/bash
set -e

echo "--- Iniciando configuración del servidor ---"

# 1. Actualizar e instalar dependencias base
echo "Instalando paquetes..."
dnf update -y
dnf install -y nodejs npm nginx unzip

# 2. Instalar PM2 globalmente
echo "Instalando PM2..."
npm install -g pm2

# 3. Configurar Nginx (Reverse Proxy 80 -> 3000)
echo "Configurando Nginx..."
cat <<EOF > /etc/nginx/conf.d/app.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Remover config por defecto si conflictúa (opcional, en AL2023 a veces es necesario)
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;
    include /etc/nginx/conf.d/*.conf;
}
EOF

# 4. Iniciar servicios
echo "Iniciando Nginx..."
systemctl enable nginx
systemctl restart nginx

echo "--- Servidor configurado correctamente ---"
echo "Versiones:"
node -v
npm -v
pm2 -v
nginx -v
