# Guía para Probar el Servidor de la Aplicación

Esta guía te ayudará a verificar que el servidor de la aplicación está funcionando correctamente y cómo acceder a él.

## 📋 Índice

1. [Obtener Información de Acceso](#1-obtener-información-de-acceso)
2. [Acceso por IP Pública (si EC2 está en subnet pública)](#2-acceso-por-ip-pública-si-ec2-está-en-subnet-pública)
3. [Acceso a través de CloudFront](#3-acceso-a-través-de-cloudfront)
4. [Acceso a través de ALB](#4-acceso-a-través-de-alb)
5. [Verificar que el Servidor está Funcionando](#5-verificar-que-el-servidor-está-funcionando)
6. [Scripts de Prueba](#6-scripts-de-prueba)
7. [Solución de Problemas](#7-solución-de-problemas)

---

## 1. Obtener Información de Acceso

### Obtener IP Pública de EC2

```bash
cd envs/prod

# Obtener IP pública de la instancia EC2
terraform output ec2_instance_public_ip

# Obtener IP privada
terraform output ec2_instance_private_ip

# Obtener ID de la instancia
terraform output ec2_instance_id
```

### Obtener URL de CloudFront (si está habilitado)

```bash
cd envs/prod

# Obtener dominio de CloudFront
terraform output cloudfront_distribution_domain_name

# Obtener ID de distribución
terraform output cloudfront_distribution_id
```

### Obtener DNS del ALB (si está habilitado)

```bash
cd envs/prod

# Obtener DNS del ALB
terraform output alb_dns_name
```

### Verificar Configuración Actual

```bash
cd envs/prod

# Ver todos los outputs disponibles
terraform output

# Verificar si EC2 está en subnet pública o privada
# (revisa el valor de ec2_subnet_tier en terraform.tfvars)
grep ec2_subnet_tier terraform.tfvars
```

---

## 2. Acceso por IP Pública (si EC2 está en subnet pública)

### ⚠️ Importante

**Solo puedes acceder directamente por IP pública si:**
- `ec2_subnet_tier = "public"` en tu `terraform.tfvars`
- El security group permite tráfico HTTP/HTTPS desde tu IP
- La aplicación está corriendo en la instancia EC2

### Verificar que la Instancia tiene IP Pública

```bash
cd envs/prod

# Obtener IP pública
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "null" ]; then
    echo "❌ La instancia NO tiene IP pública."
    echo "   Esto significa que está en una subnet privada."
    echo "   Usa CloudFront o ALB para acceder."
else
    echo "✅ IP pública: $PUBLIC_IP"
fi
```

### Probar Acceso HTTP

```bash
# Obtener IP pública
cd envs/prod
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)

# Probar conexión HTTP (puerto 80)
curl -v http://$PUBLIC_IP

# Probar conexión HTTPS (puerto 443)
curl -v https://$PUBLIC_IP

# Probar con timeout
curl --connect-timeout 10 --max-time 30 http://$PUBLIC_IP
```

### Probar desde el Navegador

1. Obtén la IP pública:
   ```bash
   cd envs/prod && terraform output -raw ec2_instance_public_ip
   ```

2. Abre tu navegador y visita:
   - `http://<IP_PUBLICA>`
   - `https://<IP_PUBLICA>` (si HTTPS está configurado)

### Verificar Security Group

El security group público debe permitir:
- **Puerto 80 (HTTP)** desde `0.0.0.0/0` o desde CIDRs específicos
- **Puerto 443 (HTTPS)** desde `0.0.0.0/0` o desde CIDRs específicos

```bash
# Obtener ID del security group público
cd envs/prod
SG_ID=$(terraform output -raw public_security_group_id)

# Ver reglas del security group
aws ec2 describe-security-groups \
    --group-ids $SG_ID \
    --region mx-central-1 \
    --query 'SecurityGroups[0].IpPermissions' \
    --output table
```

---

## 3. Acceso a través de CloudFront

Si CloudFront está habilitado, esta es la forma **recomendada** de acceder a tu aplicación.

### Obtener URL de CloudFront

```bash
cd envs/prod

# Obtener dominio de CloudFront
CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_domain_name)
echo "URL de CloudFront: https://$CLOUDFRONT_URL"
```

### Probar Acceso

```bash
# Obtener URL
cd envs/prod
CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_domain_name)

# Probar acceso HTTP (CloudFront redirige a HTTPS)
curl -v http://$CLOUDFRONT_URL

# Probar acceso HTTPS
curl -v https://$CLOUDFRONT_URL

# Probar con headers
curl -v -H "User-Agent: Test" https://$CLOUDFRONT_URL
```

### Verificar Estado de la Distribución

```bash
cd envs/prod
DIST_ID=$(terraform output -raw cloudfront_distribution_id)

# Ver estado de la distribución
aws cloudfront get-distribution \
    --id $DIST_ID \
    --query 'Distribution.Status' \
    --output text

# Verificar que está "Deployed"
aws cloudfront get-distribution \
    --id $DIST_ID \
    --query 'Distribution.{Status:Status,Enabled:DistributionConfig.Enabled,DomainName:DomainName}' \
    --output table
```

### ⚠️ Nota sobre Propagación

CloudFront puede tardar **15-20 minutos** en propagarse completamente después de crearse o actualizarse. Si obtienes errores, espera unos minutos y vuelve a intentar.

---

## 4. Acceso a través de ALB

Si ALB está habilitado, puedes acceder directamente al balanceador de carga.

### Obtener DNS del ALB

```bash
cd envs/prod

# Obtener DNS del ALB
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "URL del ALB: http://$ALB_DNS"
```

### Probar Acceso

```bash
# Obtener DNS
cd envs/prod
ALB_DNS=$(terraform output -raw alb_dns_name)

# Probar acceso HTTP
curl -v http://$ALB_DNS

# Probar acceso HTTPS (si está configurado)
curl -v https://$ALB_DNS

# Verificar health check
curl http://$ALB_DNS/health 2>/dev/null || echo "Endpoint /health no disponible"
```

### Verificar Estado del Target Group

```bash
cd envs/prod
TG_ARN=$(terraform output -raw alb_target_group_arn)

# Ver estado de los targets
aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region mx-central-1 \
    --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason}' \
    --output table
```

**Estados esperados:**
- `healthy`: El servidor está funcionando correctamente ✅
- `unhealthy`: El servidor no responde o el health check falla ❌
- `initial`: El health check aún no se ha completado ⏳

---

## 5. Verificar que el Servidor está Funcionando

### Verificar que la Aplicación está Corriendo en EC2

Si tienes acceso SSH a la instancia:

```bash
# Conectarte a la instancia (usando bastion si está en subnet privada)
# Ver guías: CONECTAR_SSH.md o USO_BASTION.md

# Una vez conectado, verificar procesos
ps aux | grep -E 'httpd|nginx|node|python|java'

# Verificar puertos en escucha
sudo netstat -tlnp | grep -E ':80|:443|:3000|:8000'

# O con ss (más moderno)
sudo ss -tlnp | grep -E ':80|:443|:3000|:8000'

# Verificar logs de la aplicación
sudo journalctl -u your-app-service -n 50
# O si usa systemd
sudo systemctl status your-app-service
```

### Verificar desde Fuera (sin SSH)

```bash
# Obtener IP pública
cd envs/prod
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)

# Verificar que el puerto está abierto
nc -zv $PUBLIC_IP 80
nc -zv $PUBLIC_IP 443

# O con telnet
telnet $PUBLIC_IP 80

# Verificar respuesta HTTP
curl -I http://$PUBLIC_IP
```

### Verificar Health Check del ALB

```bash
cd envs/prod
TG_ARN=$(terraform output -raw alb_target_group_arn)

# Ver configuración del health check
aws elbv2 describe-target-groups \
    --target-group-arns $TG_ARN \
    --region mx-central-1 \
    --query 'TargetGroups[0].HealthCheck' \
    --output json
```

---

## 6. Scripts de Prueba

### Script Completo de Prueba

Crea un archivo `probar_servidor.sh`:

```bash
#!/bin/bash

set -e

echo "=== Prueba del Servidor de la Aplicación ==="
echo ""

cd envs/prod

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
    echo "   HTTP:"
    if curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "   Status: %{http_code}\n" http://$PUBLIC_IP; then
        echo "   ✅ HTTP funciona"
    else
        echo "   ❌ HTTP no responde"
    fi
    
    echo "   HTTPS:"
    if curl -s --connect-timeout 5 --max-time 10 -k -o /dev/null -w "   Status: %{http_code}\n" https://$PUBLIC_IP; then
        echo "   ✅ HTTPS funciona"
    else
        echo "   ⚠️  HTTPS no responde (puede ser normal si no está configurado)"
    fi
    echo ""
else
    echo "ℹ️  La instancia NO tiene IP pública (probablemente está en subnet privada)"
    echo ""
fi

# Probar CloudFront
if [ -n "$CLOUDFRONT_URL" ] && [ "$CLOUDFRONT_URL" != "null" ]; then
    echo "☁️  Probando acceso por CloudFront: $CLOUDFRONT_URL"
    if curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "   Status: %{http_code}\n" https://$CLOUDFRONT_URL; then
        echo "   ✅ CloudFront funciona"
    else
        echo "   ❌ CloudFront no responde (puede estar propagándose)"
    fi
    echo ""
fi

# Probar ALB
if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
    echo "⚖️  Probando acceso por ALB: $ALB_DNS"
    if curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "   Status: %{http_code}\n" http://$ALB_DNS; then
        echo "   ✅ ALB funciona"
    else
        echo "   ❌ ALB no responde"
    fi
    echo ""
fi

# Verificar estado de targets (si ALB existe)
if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
    echo "🏥 Verificando estado de health checks..."
    TG_ARN=$(terraform output -raw alb_target_group_arn 2>/dev/null || echo "")
    if [ -n "$TG_ARN" ]; then
        aws elbv2 describe-target-health \
            --target-group-arn $TG_ARN \
            --region mx-central-1 \
            --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}' \
            --output table 2>/dev/null || echo "   ⚠️  No se pudo obtener estado de health checks"
    fi
    echo ""
fi

echo "✅ Prueba completada"
```

### Hacer el Script Ejecutable

```bash
chmod +x probar_servidor.sh
./probar_servidor.sh
```

### Script de Prueba Simple

```bash
#!/bin/bash

cd envs/prod

# Obtener IP pública
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)

if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo "Probando servidor en http://$PUBLIC_IP"
    curl -v http://$PUBLIC_IP
else
    echo "La instancia no tiene IP pública. Usa CloudFront o ALB."
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_domain_name)
    if [ -n "$CLOUDFRONT_URL" ] && [ "$CLOUDFRONT_URL" != "null" ]; then
        echo "Probando CloudFront en https://$CLOUDFRONT_URL"
        curl -v https://$CLOUDFRONT_URL
    fi
fi
```

---

## 7. Instalar un Servidor Web Básico (si no tienes aplicación)

Si tu instancia EC2 no tiene una aplicación desplegada, puedes instalar un servidor web básico para pruebas.

### Conectarse a la Instancia

Si la instancia está en subnet privada, usa el bastion:

```bash
# Obtener IP del bastion
cd envs/prod
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Conectarse al bastion
ssh -i ~/.ssh/your-key.pem ec2-user@$BASTION_IP

# Desde el bastion, conectarse a la instancia privada
PRIVATE_IP=$(cd /path/to/project/envs/prod && terraform output -raw ec2_instance_private_ip)
ssh ec2-user@$PRIVATE_IP
```

Si la instancia está en subnet pública:

```bash
cd envs/prod
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)
ssh -i ~/.ssh/your-key.pem ec2-user@$PUBLIC_IP
```

### Instalar Apache (HTTPD) en Amazon Linux 2023

```bash
# Actualizar el sistema
sudo dnf update -y

# Instalar Apache
sudo dnf install -y httpd

# Iniciar Apache
sudo systemctl start httpd

# Habilitar Apache para que inicie automáticamente
sudo systemctl enable httpd

# Verificar que está corriendo
sudo systemctl status httpd

# Verificar que escucha en el puerto 80
sudo ss -tlnp | grep :80
```

### Crear una Página de Prueba

```bash
# Crear una página HTML simple
sudo bash -c 'cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Funcionando</title>
</head>
<body>
    <h1>✅ El servidor está funcionando correctamente!</h1>
    <p>Instancia EC2: $(hostname)</p>
    <p>Fecha: $(date)</p>
</body>
</html>
EOF'

# Verificar permisos
sudo chmod 644 /var/www/html/index.html
```

### Probar Localmente desde la Instancia

```bash
# Probar que Apache responde
curl http://localhost

# O con la IP privada
curl http://$(hostname -I | awk '{print $1}')
```

### Verificar que el Security Group Permite Tráfico desde el ALB

El security group de la instancia EC2 debe permitir tráfico HTTP (puerto 80) desde el security group del ALB.

```bash
# Obtener IDs de security groups
cd envs/prod
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
ALB_ARN=$(terraform output -raw alb_arn)

# Obtener security group de la instancia
INSTANCE_SG=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region mx-central-1 \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

# Obtener security group del ALB
ALB_SG=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --region mx-central-1 \
    --query 'LoadBalancers[0].SecurityGroups[0]' \
    --output text)

echo "Security Group de EC2: $INSTANCE_SG"
echo "Security Group del ALB: $ALB_SG"

# Verificar si EC2 permite tráfico desde ALB
aws ec2 describe-security-groups \
    --group-ids $INSTANCE_SG \
    --region mx-central-1 \
    --query "SecurityGroups[0].IpPermissions[?UserIdGroupPairs[?GroupId=='$ALB_SG']]" \
    --output json
```

Si no hay reglas que permitan tráfico desde el ALB, necesitas agregar una regla. Esto normalmente se hace en Terraform, pero puedes hacerlo manualmente:

```bash
# Agregar regla de entrada al security group de EC2
aws ec2 authorize-security-group-ingress \
    --group-id $INSTANCE_SG \
    --protocol tcp \
    --port 80 \
    --source-group $ALB_SG \
    --region mx-central-1
```

### Verificar Health Check del ALB

Después de instalar Apache, espera unos minutos y verifica el estado del health check:

```bash
cd envs/prod
TG_ARN=$(terraform output -raw alb_target_group_arn)

# Ver estado de health checks
aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region mx-central-1 \
    --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State,Reason:TargetHealth.Reason}' \
    --output table
```

El estado debería cambiar a `healthy` después de unos minutos.

---

## 8. Solución de Problemas

### Problema: No puedo acceder por IP pública

**Posibles causas:**

1. **La instancia está en subnet privada**
   ```bash
   # Verificar configuración
   cd envs/prod
   grep ec2_subnet_tier terraform.tfvars
   ```
   **Solución:** Usa CloudFront o ALB para acceder.

2. **El security group no permite tu IP**
   ```bash
   # Verificar reglas del security group
   cd envs/prod
   SG_ID=$(terraform output -raw public_security_group_id)
   aws ec2 describe-security-groups --group-ids $SG_ID --region mx-central-1
   ```
   **Solución:** Ajusta `allowed_public_ingress_cidrs` en `terraform.tfvars`.

3. **La aplicación no está corriendo**
   ```bash
   # Conectarte a la instancia y verificar
   ssh -i ~/.ssh/your-key.pem ec2-user@$PUBLIC_IP
   sudo systemctl status your-app
   ```

4. **El puerto no está abierto**
   ```bash
   # Verificar desde fuera
   nc -zv $PUBLIC_IP 80
   ```

### Problema: CloudFront no responde

**Posibles causas:**

1. **La distribución aún se está propagando**
   - Espera 15-20 minutos después de crear/actualizar
   - Verifica el estado: `aws cloudfront get-distribution --id <ID>`

2. **El origen (ALB/EC2) no está funcionando**
   - Verifica que el origen responda directamente
   - Revisa los logs de CloudFront

3. **WAF está bloqueando el tráfico**
   ```bash
   # Verificar reglas del WAF
   cd envs/prod
   WAF_ID=$(terraform output -raw waf_web_acl_id)
   aws wafv2 get-web-acl --scope CLOUDFRONT --id $WAF_ID --region us-east-1
   ```

### Problema: ALB muestra targets como "unhealthy"

**Posibles causas:**

1. **La aplicación no responde en la ruta del health check**
   - Verifica la ruta configurada: `/` por defecto
   - Asegúrate de que la aplicación responda en esa ruta

2. **El security group no permite tráfico del ALB**
   - El security group de EC2 debe permitir tráfico desde el security group del ALB

3. **La aplicación no está corriendo**
   - Conecta por SSH y verifica que la aplicación esté activa

### Problema: Timeout al conectar

**Posibles causas:**

1. **Security group bloqueando el tráfico**
   - Verifica las reglas de entrada

2. **Network ACL bloqueando el tráfico**
   - Verifica las reglas de Network ACL

3. **La instancia está detenida**
   ```bash
   # Verificar estado de la instancia
   cd envs/prod
   INSTANCE_ID=$(terraform output -raw ec2_instance_id)
   aws ec2 describe-instances --instance-ids $INSTANCE_ID --region mx-central-1 \
       --query 'Reservations[0].Instances[0].State.Name' --output text
   ```

---

## 📝 Resumen de Comandos Útiles

```bash
# Obtener IP pública
cd envs/prod && terraform output -raw ec2_instance_public_ip

# Obtener URL de CloudFront
cd envs/prod && terraform output -raw cloudfront_distribution_domain_name

# Obtener DNS del ALB
cd envs/prod && terraform output -raw alb_dns_name

# Probar HTTP
curl -v http://<IP_O_URL>

# Probar HTTPS
curl -v https://<IP_O_URL>

# Verificar estado de health checks
cd envs/prod && \
TG_ARN=$(terraform output -raw alb_target_group_arn) && \
aws elbv2 describe-target-health --target-group-arn $TG_ARN --region mx-central-1

# Verificar estado de CloudFront
cd envs/prod && \
DIST_ID=$(terraform output -raw cloudfront_distribution_id) && \
aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status'
```

---

**Última actualización**: 2024

