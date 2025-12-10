#!/bin/bash
# Diagnóstico detallado de conectividad NAT Gateway

echo "=========================================="
echo "Diagnóstico Detallado NAT Gateway"
echo "=========================================="
echo ""

echo "1. Información de red de la instancia:"
ip addr show ens5
echo ""

echo "2. Tabla de ruteo completa:"
ip route show
echo ""

echo "3. Verificar conectividad con gateway local (10.0.2.1):"
ping -c 2 10.0.2.1 2>&1
echo ""

echo "4. Verificar conectividad con IP del NAT Gateway (10.0.1.194):"
ping -c 2 10.0.1.194 2>&1
echo ""

echo "5. Verificar conectividad con otra instancia en subnet pública (si existe):"
# Esto requiere conocer la IP del bastion
echo "Bastion IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'N/A')"
echo ""

echo "6. Verificar metadata service (debe funcionar siempre):"
curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id || echo "❌ No se puede acceder"
echo ""

echo "7. Verificar tabla ARP:"
arp -a | head -5
echo ""

echo "8. Verificar interfaces de red:"
ip link show
echo ""

echo "9. Intentar traceroute a 8.8.8.8 (si está disponible):"
which traceroute && traceroute -m 5 8.8.8.8 2>&1 | head -10 || echo "traceroute no disponible"
echo ""

echo "10. Verificar si hay firewall local:"
if command -v iptables &> /dev/null; then
    echo "Reglas iptables:"
    sudo iptables -L -n -v 2>/dev/null | head -20 || echo "Requiere sudo"
else
    echo "iptables no disponible"
fi
echo ""

echo "=========================================="
echo "Para capturar tráfico (ejecutar en otra terminal):"
echo "sudo tcpdump -i ens5 -n 'icmp or tcp port 80 or tcp port 443'"
echo "=========================================="

