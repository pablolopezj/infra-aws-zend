#!/bin/bash
# Script de diagnóstico para verificar acceso a internet desde EC2

echo "=========================================="
echo "Diagnóstico de Acceso a Internet"
echo "=========================================="
echo ""

echo "1. Verificando tabla de ruteo local:"
ip route show
echo ""

echo "2. Verificando conectividad con metadata service (debe funcionar):"
curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id || echo "❌ No se puede acceder al metadata service"
echo ""

echo "3. Verificando DNS:"
nslookup google.com 2>&1 | head -5 || echo "❌ Problema con DNS"
echo ""

echo "4. Probando ping a 8.8.8.8 (Google DNS):"
ping -c 3 8.8.8.8 2>&1 || echo "❌ No se puede hacer ping a 8.8.8.8"
echo ""

echo "5. Probando curl a Google:"
curl -I --max-time 5 https://www.google.com 2>&1 | head -3 || echo "❌ No se puede acceder a Google"
echo ""

echo "6. Verificando gateway por defecto:"
ip route | grep default || echo "⚠️  No se encontró ruta por defecto"
echo ""

echo "7. Verificando interfaces de red:"
ip addr show | grep -A 2 "inet " || ifconfig | grep -A 2 "inet "
echo ""

echo "8. Verificando si hay firewall local:"
if command -v iptables &> /dev/null; then
    echo "Reglas iptables OUTPUT:"
    sudo iptables -L OUTPUT -n -v 2>/dev/null | head -10 || echo "No se pueden ver reglas (requiere sudo)"
else
    echo "iptables no disponible"
fi
echo ""

echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="

