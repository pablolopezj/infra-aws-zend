#!/bin/bash
# Script para verificar acceso a Internet desde la instancia privada

echo "=== Verificando acceso a Internet desde instancia privada ==="
echo ""

echo "1. Verificando ruta por defecto:"
ip route | grep default
echo ""

echo "2. Verificando IP privada de la instancia:"
hostname -I
echo ""

echo "3. Ping al NAT Gateway (IP privada 10.0.1.135):"
ping -c 3 10.0.1.135
echo ""

echo "4. Ping a Internet (8.8.8.8):"
ping -c 3 8.8.8.8
echo ""

echo "5. HTTP a Internet (8.8.8.8):"
curl -I --max-time 5 http://8.8.8.8 2>&1
echo ""

echo "6. HTTPS a Google:"
curl -I --max-time 5 https://www.google.com 2>&1
echo ""

echo "7. Verificando DNS:"
nslookup google.com 2>&1 || dig google.com 2>&1
echo ""

echo "8. Verificando conectividad con bastion (10.0.1.232):"
ping -c 2 10.0.1.232
echo ""

echo "=== Verificación completada ==="

