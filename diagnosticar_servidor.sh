#!/bin/bash

set -e

echo "=== Diagnóstico Detallado del Servidor ==="
echo ""

cd envs/prod

# Obtener información
echo "📋 Información de la infraestructura:"
INSTANCE_ID=$(terraform output -raw ec2_instance_id 2>/dev/null || echo "")
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip 2>/dev/null || echo "")
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip 2>/dev/null || echo "")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
TG_ARN=$(terraform output -raw alb_target_group_arn 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_domain_name 2>/dev/null || echo "")

echo "   Instancia ID: ${INSTANCE_ID:-'N/A'}"
echo "   IP Privada: ${PRIVATE_IP:-'N/A'}"
echo "   IP Pública: ${PUBLIC_IP:-'N/A (subnet privada)'}"
echo ""

# 1. Verificar estado de la instancia EC2
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
    echo "🔍 1. Estado de la instancia EC2:"
    INSTANCE_STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region mx-central-1 \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null || echo "unknown")
    
    echo "   Estado: $INSTANCE_STATE"
    
    if [ "$INSTANCE_STATE" != "running" ]; then
        echo "   ⚠️  La instancia NO está corriendo. Estado: $INSTANCE_STATE"
        echo "   💡 Solución: Inicia la instancia con: aws ec2 start-instances --instance-ids $INSTANCE_ID --region mx-central-1"
    else
        echo "   ✅ La instancia está corriendo"
    fi
    echo ""
fi

# 2. Verificar health checks del ALB
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "null" ]; then
    echo "🏥 2. Estado de Health Checks del ALB:"
    aws elbv2 describe-target-health \
        --target-group-arn $TG_ARN \
        --region mx-central-1 \
        --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}' \
        --output table 2>/dev/null || echo "   ⚠️  No se pudo obtener estado"
    
    # Obtener detalles del health check
    echo ""
    echo "   Configuración del Health Check:"
    aws elbv2 describe-target-groups \
        --target-group-arns $TG_ARN \
        --region mx-central-1 \
        --query 'TargetGroups[0].HealthCheck.{Path:HealthCheckPath,Protocol:HealthCheckProtocol,Port:HealthCheckPort,Interval:HealthCheckIntervalSeconds,Timeout:HealthCheckTimeoutSeconds,HealthyThreshold:HealthyThresholdCount,UnhealthyThreshold:UnhealthyThresholdCount}' \
        --output table 2>/dev/null || echo "   ⚠️  No se pudo obtener configuración"
    echo ""
fi

# 3. Verificar Security Groups
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
    echo "🔒 3. Security Groups de la instancia:"
    INSTANCE_SGS=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region mx-central-1 \
        --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCE_SGS" ]; then
        for SG_ID in $INSTANCE_SGS; do
            echo "   Security Group: $SG_ID"
            echo "   Reglas de entrada:"
            aws ec2 describe-security-groups \
                --group-ids $SG_ID \
                --region mx-central-1 \
                --query 'SecurityGroups[0].IpPermissions[?FromPort==`80` || FromPort==`443` || FromPort==`22`].{Port:FromPort,Protocol:IpProtocol,Source:IpRanges[*].CidrIp|[0],SourceSG:UserIdGroupPairs[*].GroupId|[0]}' \
                --output table 2>/dev/null || echo "      ⚠️  No se pudieron obtener reglas"
        done
    fi
    echo ""
fi

# 4. Verificar Security Group del ALB
if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
    echo "🔒 4. Security Group del ALB:"
    ALB_ARN=$(terraform output -raw alb_arn 2>/dev/null || echo "")
    if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "null" ]; then
        ALB_SGS=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns $ALB_ARN \
            --region mx-central-1 \
            --query 'LoadBalancers[0].SecurityGroups' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$ALB_SGS" ]; then
            for SG_ID in $ALB_SGS; do
                echo "   Security Group: $SG_ID"
                echo "   Reglas de entrada:"
                aws ec2 describe-security-groups \
                    --group-ids $SG_ID \
                    --region mx-central-1 \
                    --query 'SecurityGroups[0].IpPermissions[?FromPort==`80` || FromPort==`443`].{Port:FromPort,Protocol:IpProtocol,Source:IpRanges[*].CidrIp|[0]}' \
                    --output table 2>/dev/null || echo "      ⚠️  No se pudieron obtener reglas"
            done
        fi
    fi
    echo ""
fi

# 5. Verificar si hay un servicio web corriendo (requiere SSH)
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_STATE" = "running" ]; then
    echo "🌐 5. Verificación de servicios web:"
    echo "   ⚠️  Para verificar si hay un servicio web corriendo, necesitas conectarte por SSH:"
    echo ""
    echo "   Si tienes acceso SSH, ejecuta estos comandos en la instancia:"
    echo "   - sudo netstat -tlnp | grep -E ':80|:443|:3000|:8000'"
    echo "   - sudo ss -tlnp | grep -E ':80|:443|:3000|:8000'"
    echo "   - ps aux | grep -E 'httpd|nginx|node|python|java'"
    echo "   - sudo systemctl status httpd nginx 2>/dev/null || echo 'No hay servicios web instalados'"
    echo ""
    echo "   💡 Si no hay servicio web corriendo, necesitas:"
    echo "      1. Instalar y configurar un servidor web (Apache, Nginx, etc.)"
    echo "      2. O desplegar tu aplicación"
    echo "      3. Asegurarte de que escuche en el puerto 80 (HTTP) o 443 (HTTPS)"
    echo ""
fi

# 6. Verificar conectividad desde ALB a EC2
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "null" ]; then
    echo "🔗 6. Conectividad ALB -> EC2:"
    echo "   Verificando si el security group de EC2 permite tráfico desde el ALB..."
    
    # Obtener security group del ALB
    if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "null" ]; then
        ALB_SG=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns $ALB_ARN \
            --region mx-central-1 \
            --query 'LoadBalancers[0].SecurityGroups[0]' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$ALB_SG" ] && [ -n "$INSTANCE_SGS" ]; then
            echo "   Security Group del ALB: $ALB_SG"
            echo "   Security Groups de EC2: $INSTANCE_SGS"
            echo ""
            echo "   Verificando si EC2 permite tráfico desde ALB..."
            
            # Verificar si el security group de EC2 permite tráfico desde el ALB
            for SG_ID in $INSTANCE_SGS; do
                ALLOWS_ALB=$(aws ec2 describe-security-groups \
                    --group-ids $SG_ID \
                    --region mx-central-1 \
                    --query "SecurityGroups[0].IpPermissions[?UserIdGroupPairs[?GroupId=='$ALB_SG']]" \
                    --output text 2>/dev/null || echo "")
                
                if [ -n "$ALLOWS_ALB" ]; then
                    echo "   ✅ El security group $SG_ID permite tráfico desde el ALB"
                else
                    echo "   ❌ El security group $SG_ID NO permite tráfico desde el ALB"
                    echo "   💡 Solución: Agrega una regla de entrada que permita tráfico desde el security group del ALB"
                fi
            done
        fi
    fi
    echo ""
fi

# 7. Resumen y recomendaciones
echo "=== Resumen y Recomendaciones ==="
echo ""

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ PROBLEMA CRÍTICO: La instancia no está corriendo"
    echo "   Solución: Inicia la instancia"
    echo ""
fi

if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "null" ]; then
    UNHEALTHY_COUNT=$(aws elbv2 describe-target-health \
        --target-group-arn $TG_ARN \
        --region mx-central-1 \
        --query 'length(TargetHealthDescriptions[?TargetHealth.State==`unhealthy`])' \
        --output text 2>/dev/null || echo "0")
    
    if [ "$UNHEALTHY_COUNT" != "0" ]; then
        echo "❌ PROBLEMA: Hay $UNHEALTHY_COUNT target(s) unhealthy en el ALB"
        echo "   Posibles causas:"
        echo "   1. No hay servicio web corriendo en la instancia"
        echo "   2. El servicio web no responde en la ruta del health check (/)"
        echo "   3. El security group de EC2 no permite tráfico desde el ALB"
        echo "   4. El puerto del servicio web no coincide con el configurado en el target group"
        echo ""
    fi
fi

echo "📝 Próximos pasos:"
echo "   1. Conecta por SSH a la instancia (usa el bastion si está en subnet privada)"
echo "   2. Verifica si hay un servicio web instalado y corriendo"
echo "   3. Si no hay servicio web, instala uno (Apache, Nginx, etc.)"
echo "   4. Asegúrate de que el servicio escuche en el puerto 80"
echo "   5. Verifica que el security group de EC2 permita tráfico desde el ALB"
echo "   6. Prueba acceder localmente desde la instancia: curl http://localhost"
echo ""

echo "✅ Diagnóstico completado"

