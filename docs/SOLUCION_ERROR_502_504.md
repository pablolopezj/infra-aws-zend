# Solución para Errores 502 y 504

## 🔍 Diagnóstico del Problema

Los errores que estás viendo:
- **502 Bad Gateway** (ALB): El ALB no puede conectarse a las instancias EC2
- **504 Gateway Timeout** (CloudFront): CloudFront no puede conectarse al origen (ALB)

Esto indica que hay **dos problemas principales**:

1. **No hay servicio web corriendo** en la instancia EC2
2. **El security group de EC2 no permite tráfico desde el ALB** (si la instancia está en subnet privada)

---

## ✅ Solución Paso a Paso

### Paso 1: Verificar el Estado Actual

Ejecuta el script de diagnóstico:

```bash
./diagnosticar_servidor.sh
```

Esto te mostrará:
- Estado de la instancia EC2
- Estado de los health checks del ALB
- Configuración de security groups
- Problemas de conectividad

### Paso 2: Instalar un Servidor Web

Conéctate a tu instancia EC2 (usa el bastion si está en subnet privada):

```bash
# Obtener IP del bastion
cd envs/prod
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Conectarse al bastion
ssh -i ~/.ssh/your-key.pem ec2-user@$BASTION_IP

# Desde el bastion, conectarse a la instancia privada
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip)
ssh ec2-user@$PRIVATE_IP
```

Una vez conectado, instala Apache:

```bash
# Actualizar sistema
sudo dnf update -y

# Instalar Apache
sudo dnf install -y httpd

# Iniciar y habilitar Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Verificar que está corriendo
sudo systemctl status httpd

# Crear página de prueba
sudo bash -c 'cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Funcionando</title>
</head>
<body>
    <h1>✅ El servidor está funcionando correctamente!</h1>
    <p>Instancia: $(hostname)</p>
    <p>Fecha: $(date)</p>
</body>
</html>
EOF'

# Probar localmente
curl http://localhost
```

### Paso 3: Verificar Security Group

El problema más común es que el security group de la instancia EC2 (en subnet privada) **no permite tráfico desde el security group del ALB**.

Verifica esto:

```bash
cd envs/prod

# Obtener IDs
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
ALB_ARN=$(terraform output -raw alb_arn)

# Obtener security groups
INSTANCE_SG=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region mx-central-1 \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

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

Si el resultado está vacío `[]`, **necesitas agregar una regla**.

### Paso 4: Agregar Regla al Security Group

Agrega una regla que permita tráfico HTTP (puerto 80) desde el security group del ALB:

```bash
# Agregar regla de entrada
aws ec2 authorize-security-group-ingress \
    --group-id $INSTANCE_SG \
    --protocol tcp \
    --port 80 \
    --source-group $ALB_SG \
    --region mx-central-1
```

### Paso 5: Verificar Health Checks

Después de agregar la regla y asegurarte de que Apache está corriendo, espera 2-3 minutos y verifica los health checks:

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

### Paso 6: Probar Nuevamente

Ejecuta el script de prueba:

```bash
./probar_servidor.sh
```

Ahora deberías ver:
- ✅ ALB funciona - Status: 200 (en lugar de 502)
- ✅ CloudFront funciona - Status: 200 (en lugar de 504)

---

## 🔧 Solución Permanente con Terraform

✅ **La solución permanente ya está implementada en el código.**

Las reglas de security group para permitir tráfico desde el ALB a las instancias EC2 en subnet privada ya están configuradas en `envs/prod/main.tf`.

Para aplicar los cambios:

```bash
cd envs/prod
terraform plan
terraform apply
```

Esto creará automáticamente las reglas necesarias:
- Permite tráfico HTTP (puerto 80) desde el ALB a EC2 en subnet privada
- Permite tráfico HTTPS (puerto 443) desde el ALB a EC2 en subnet privada

**Nota:** Si ya tienes la infraestructura desplegada, puedes aplicar estos cambios sin afectar los recursos existentes. Solo se agregarán las nuevas reglas de security group.

---

## 📋 Checklist de Verificación

- [ ] Instancia EC2 está corriendo
- [ ] Apache (o tu aplicación) está instalado y corriendo
- [ ] Apache responde en `http://localhost` desde la instancia
- [ ] Security group de EC2 permite tráfico HTTP (puerto 80) desde el ALB
- [ ] Health checks del ALB muestran estado `healthy`
- [ ] ALB responde con status 200
- [ ] CloudFront responde con status 200

---

## 🚨 Problemas Comunes

### El health check sigue mostrando "unhealthy"

1. **Verifica que Apache esté corriendo:**
   ```bash
   sudo systemctl status httpd
   ```

2. **Verifica que Apache escuche en el puerto 80:**
   ```bash
   sudo ss -tlnp | grep :80
   ```

3. **Verifica que el health check path sea correcto:**
   ```bash
   curl http://localhost/
   ```

4. **Verifica los logs del health check:**
   - Ve a la consola AWS → EC2 → Target Groups
   - Revisa la pestaña "Health checks" para ver el motivo del fallo

### El security group no permite tráfico

Si después de agregar la regla manualmente sigue sin funcionar:

1. **Verifica que la regla se agregó correctamente:**
   ```bash
   aws ec2 describe-security-groups --group-ids $INSTANCE_SG --region mx-central-1
   ```

2. **Verifica que el ALB esté en la misma VPC:**
   ```bash
   aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --region mx-central-1
   ```

### CloudFront sigue dando 504

1. **Espera 15-20 minutos** después de que el ALB funcione (CloudFront tarda en propagarse)

2. **Verifica que CloudFront apunte al ALB correcto:**
   ```bash
   cd envs/prod
   DIST_ID=$(terraform output -raw cloudfront_distribution_id)
   aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.DistributionConfig.Origins' --output json
   ```

3. **Invalida la caché de CloudFront:**
   ```bash
   aws cloudfront create-invalidation \
       --distribution-id $DIST_ID \
       --paths "/*"
   ```

---

**Última actualización**: 2024

