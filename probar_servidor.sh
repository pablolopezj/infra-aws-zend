#!/bin/bash

set -e

echo "=== Prueba del Servidor de la Aplicación ==="
echo ""

cd envs/prod

# Verificar que estamos en el directorio correcto
if [ ! -f "main.tf" ]; then
    echo "❌ Error: No se encontró main.tf. Asegúrate de estar en el directorio correcto."
    exit 1
fi

# Obtener información
echo "📋 Obteniendo información de la infraestructura..."
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip 2>/dev/null || echo "")
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_domain_name 2>/dev/null || echo "")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")

echo ""

# Probar IP pública (si existe)
if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo "🌐 Probando acceso por IP pública: $PUBLIC_IP"
    echo "   HTTP (puerto 80):"
    HTTP_STATUS=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://$PUBLIC_IP 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" != "000" ] && [ "$HTTP_STATUS" != "" ]; then
        echo "   ✅ HTTP funciona - Status: $HTTP_STATUS"
    else
        echo "   ❌ HTTP no responde o timeout"
    fi
    
    echo "   HTTPS (puerto 443):"
    HTTPS_STATUS=$(curl -s --connect-timeout 5 --max-time 10 -k -o /dev/null -w "%{http_code}" https://$PUBLIC_IP 2>/dev/null || echo "000")
    if [ "$HTTPS_STATUS" != "000" ] && [ "$HTTPS_STATUS" != "" ]; then
        echo "   ✅ HTTPS funciona - Status: $HTTPS_STATUS"
    else
        echo "   ⚠️  HTTPS no responde (puede ser normal si no está configurado)"
    fi
    echo ""
else
    echo "ℹ️  La instancia NO tiene IP pública (probablemente está en subnet privada)"
    echo "   IP privada: ${PRIVATE_IP:-'N/A'}"
    echo ""
fi

# Probar CloudFront
if [ -n "$CLOUDFRONT_URL" ] && [ "$CLOUDFRONT_URL" != "null" ]; then
    echo "☁️  Probando acceso por CloudFront: https://$CLOUDFRONT_URL"
    CLOUDFRONT_STATUS=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://$CLOUDFRONT_URL 2>/dev/null || echo "000")
    if [ "$CLOUDFRONT_STATUS" != "000" ] && [ "$CLOUDFRONT_STATUS" != "" ]; then
        echo "   ✅ CloudFront funciona - Status: $CLOUDFRONT_STATUS"
        echo "   🌐 URL completa: https://$CLOUDFRONT_URL"
    else
        echo "   ❌ CloudFront no responde (puede estar propagándose, espera 15-20 min)"
    fi
    echo ""
fi

# Probar ALB
if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
    echo "⚖️  Probando acceso por ALB: http://$ALB_DNS"
    ALB_STATUS=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://$ALB_DNS 2>/dev/null || echo "000")
    if [ "$ALB_STATUS" != "000" ] && [ "$ALB_STATUS" != "" ]; then
        echo "   ✅ ALB funciona - Status: $ALB_STATUS"
    else
        echo "   ❌ ALB no responde"
    fi
    echo ""
    
    # Verificar estado de targets
    echo "🏥 Verificando estado de health checks del ALB..."
    TG_ARN=$(terraform output -raw alb_target_group_arn 2>/dev/null || echo "")
    if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "null" ]; then
        aws elbv2 describe-target-health \
            --target-group-arn $TG_ARN \
            --region mx-central-1 \
            --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason}' \
            --output table 2>/dev/null || echo "   ⚠️  No se pudo obtener estado de health checks"
    fi
    echo ""
fi

# Resumen
echo "=== Resumen ==="
if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo "✅ Puedes acceder directamente por IP pública: http://$PUBLIC_IP"
fi
if [ -n "$CLOUDFRONT_URL" ] && [ "$CLOUDFRONT_URL" != "null" ]; then
    echo "✅ Puedes acceder por CloudFront: https://$CLOUDFRONT_URL"
fi
if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
    echo "✅ Puedes acceder por ALB: http://$ALB_DNS"
fi

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
    if [ -z "$CLOUDFRONT_URL" ] || [ "$CLOUDFRONT_URL" = "null" ]; then
        if [ -z "$ALB_DNS" ] || [ "$ALB_DNS" = "null" ]; then
            echo "⚠️  No se encontraron métodos de acceso configurados."
            echo "   Verifica tu configuración en terraform.tfvars"
        fi
    fi
fi

echo ""
echo "✅ Prueba completada"

