# Operational Runbook - infra-aws-zend

> **Región**: mx-central-1 | **Entorno**: prod

## Índice

1. [Inicializar Terraform](#1-inicializar-terraform)
2. [Revisar Plan](#2-revisar-plan)
3. [Aplicar Cambios](#3-aplicar-cambios)
4. [Revisar Outputs](#4-revisar-outputs)
5. [Conectarse a EC2 por SSM](#5-conectarse-a-ec2-por-ssm)
6. [Conectarse a RDS por Túnel SSM](#6-conectarse-a-rds-por-túnel-ssm)
7. [Revisar CloudFront](#7-revisar-cloudfront)
8. [Revisar ALB Target Health](#8-revisar-alb-target-health)
9. [Revisar Secrets Manager](#9-revisar-secrets-manager)
10. [Resolver Problemas de Lock](#10-resolver-problemas-de-lock)
11. [Verificar Infraestructura](#11-verificar-infraestructura)
12. [Emergencias](#12-emergencias)

---

## 1. Inicializar Terraform

### Bootstrap (primera vez)

```bash
cd envs/bootstrap
terraform init
terraform plan
terraform apply
terraform output
```

### Producción

```bash
cd envs/prod
terraform init
# Si pide migrar state, responder "yes"

# Inicializar con reconfiguración (si hay error de backend)
terraform init -reconfigure

# Verificar providers
terraform providers
```

---

## 2. Revisar Plan

```bash
cd envs/prod

# Plan completo
terraform plan

# Plan con variables específicas
terraform plan -var="enable_bastion=true"

# Plan detallado (mostrar cambios)
terraform plan -out=tfplan
terraform show tfplan

# Buscar destrucciones
terraform plan 2>&1 | grep -i "destroy"

# Plan contra state remoto
terraform plan -state=terraform.tfstate
```

### Qué verificar en el plan

- [ ] No hay recursos marcados para destrucción inesperada
- [ ] Los CIDRs son correctos
- [ ] Las AZs son correctas
- [ ] Los tipos de instancia son correctos
- [ ] WAF se crea en us-east-1 (provider alias)
- [ ] Los módulos condicionales se crean/desactivan correctamente

---

## 3. Aplicar Cambios

```bash
cd envs/prod

# Aplicar con confirmación
terraform apply

# Aplicar plan guardado
terraform apply tfplan

# Aplicar sin confirmación (CI/CD)
terraform apply -auto-approve

# Aplicar con variables específicas
terraform apply -var="enable_bastion=true"

# Aplicar solo un módulo (usar con precaución)
terraform apply -target=module.network
```

### Tiempos esperados

| Recurso | Tiempo |
|---------|--------|
| VPC + Networking | 2-3 min |
| NAT Gateway | 1-2 min |
| EC2 | 1-2 min |
| RDS | 10-15 min |
| ALB | 2-3 min |
| CloudFront | 5-15 min |
| WAF | 1-2 min |

---

## 4. Revisar Outputs

```bash
# Todos los outputs
terraform output

# Output específico
terraform output vpc_id
terraform output cloudfront_distribution_domain_name
terraform output rds_endpoint
terraform output ec2_instance_id
terraform output s3_bucket_id

# Output en formato JSON
terraform output -json

# Output sin formato (para scripts)
terraform output -raw ec2_instance_id
```

### Outputs principales

| Output | Descripción | Cómo obtenerlo |
|--------|-------------|---------------|
| `vpc_id` | ID de la VPC | `terraform output vpc_id` |
| `ec2_instance_id` | ID de instancia EC2 | `terraform output ec2_instance_id` |
| `rds_endpoint` | Endpoint de RDS | `terraform output rds_endpoint` |
| `cloudfront_distribution_domain_name` | URL de CloudFront | `terraform output cloudfront_distribution_domain_name` |
| `alb_dns_name` | DNS del ALB | `terraform output alb_dns_name` |
| `s3_bucket_id` | Nombre del bucket S3 | `terraform output s3_bucket_id` |
| `ecr_repository_url` | URL del repositorio ECR | `terraform output ecr_repository_url` |
| `waf_web_acl_arn` | ARN del WAF Web ACL | `terraform output waf_web_acl_arn` |

---

## 5. Conectarse a EC2 por SSM

### Prerequisitos

1. AWS CLI configurado con permisos SSM
2. Plugin Session Manager instalado
3. Instancia EC2 tiene IAM role con `AmazonSSMManagedInstanceCore` (ya configurado)

### Conexión

```bash
# Obtener ID de la instancia
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
echo "Instance ID: $INSTANCE_ID"

# Iniciar sesión SSM
aws ssm start-session \
  --target $INSTANCE_ID \
  --region mx-central-1

# Con puerto SSH forwarding (para usar con SSH clients)
aws ssm start-session \
  --target $INSTANCE_ID \
  --document-name AWS-StartSSHSession \
  --parameters portNumber=22 \
  --region mx-central-1
```

### Troubleshooting SSM

```bash
# Verificar que el agente SSM está corriendo
aws ssm describe-instance-information \
  --instance-filter-words "InstanceIds=$INSTANCE_ID" \
  --region mx-central-1

# Verificar conectividad
aws ssm list-instances \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --region mx-central-1
```

---

## 6. Conectarse a RDS por Túnel SSM

### Método 1: Port Forwarding (Recomendado)

```bash
# Obtener variables
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
RDS_ADDRESS=$(terraform output -raw rds_address)

# Crear túnel (puerto local 5433 → RDS puerto 5432)
aws ssm start-session \
  --target $INSTANCE_ID \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["'$RDS_ADDRESS'"],"portNumber":["5432"], "localPortNumber":["5433"]}' \
  --region mx-central-1

# Conectar con psql (en otra terminal)
psql -h localhost -p 5433 -U scorpion_db_user -d zenddb

# Conectar con pgAdmin u otro cliente
# Host: localhost
# Port: 5433
# Database: zenddb
# Username: (obtener de Secrets Manager)
```

### Método 2: Obtener credenciales de Secrets Manager

```bash
# Obtener ARN del secreto
SECRET_NAME="zend-app-prod-mxc1-rds-credentials"

# Obtener credenciales
aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region mx-central-1 \
  --query SecretString --output text | jq .

# Extraer campos individuales
aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region mx-central-1 \
  --query SecretString --output text | jq -r '.password'
```

---

## 7. Revisar CloudFront

```bash
# Obtener ID de distribución
DIST_ID=$(terraform output -raw cloudfront_distribution_id)

# Ver estado de la distribución
aws cloudfront get-distribution \
  --id $DIST_ID \
  --query 'Distribution.Status'

# Ver configuración de cache
aws cloudfront get-distribution \
  --id $DIST_ID \
  --query 'Distribution.DistributionConfig.DefaultCacheBehavior'

# Invalidar cache (después de deployment)
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"

# Ver métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --dimensions DistributionId=$DIST_ID
```

---

## 8. Revisar ALB Target Health

```bash
# Obtener ARN del Target Group
TG_ARN=$(terraform output -raw alb_target_group_arn)

# Verificar salud de targets
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region mx-central-1

# Ver detalle de un target específico
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --targets Id=$INSTANCE_ID \
  --region mx-central-1
```

---

## 9. Revisar Secrets Manager

```bash
# Listar secretos
aws secretsmanager list-secrets \
  --region mx-central-1

# Obtener valor del secreto RDS
aws secretsmanager get-secret-value \
  --secret-id zend-app-prod-mxc1-rds-credentials \
  --region mx-central-1 \
  --query SecretString --output text | jq .

# Rotar contraseña (requiere Lambda de rotación)
# No implementado actualmente - ver recomendaciones
```

---

## 10. Resolver Problemas de Lock

### Error: "Error acquiring the state lock"

```bash
# Verificar locks activos
aws dynamodb scan \
  --table-name zend-terraform-locks \
  --region mx-central-1

# Forzar unlock (¡ÚSOLO si estás seguro de que no hay otro proceso ejecutándose!)
terraform force-unlock <LOCK_ID>

# El LOCK_ID aparece en el mensaje de error
```

### Error: "Error loading state: AccessDenied"

```bash
# Verificar acceso al bucket S3
aws s3 ls s3://zend-terraform-state/ --region mx-central-1

# Verificar permisos
aws sts get-caller-identity
```

---

## 11. Verificar Infraestructura

### Verificar VPC

```bash
VPC_ID=$(terraform output -raw vpc_id)

aws ec2 describe-vpcs \
  --vpc-ids $VPC_ID \
  --region mx-central-1
```

### Verificar Subnets

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region mx-central-1
```

### Verificar Security Groups

```bash
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region mx-central-1
```

### Verificar RDS

```bash
aws rds describe-db-instances \
  --db-instance-identifier zend-app-prod-mxc1-postgres \
  --region mx-central-1
```

### Verificar EC2

```bash
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1
```

---

## 12. Emergencias

### EC2 no responde

```bash
# 1. Verificar estado
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --region mx-central-1

# 2. Reiniciar instancia
aws ec2 reboot-instance \
  --instance-id $INSTANCE_ID \
  --region mx-central-1

# 3. Si no funciona, detener y arrancar
aws ec2 stop-instance --instance-id $INSTANCE_ID --region mx-central-1
aws ec2 start-instance --instance-id $INSTANCE_ID --region mx-central-1
```

### RDS no responde

```bash
# 1. Verificar estado
aws rds describe-db-instances \
  --db-instance-identifier zend-app-prod-mxc1-postgres \
  --region mx-central-1

# 2. Reboot
aws rds reboot-db-instance \
  --db-instance-identifier zend-app-prod-mxc1-postgres \
  --region mx-central-1
```

### CloudFront devuelve errores 5xx

```bash
# 1. Verificar ALB target health
# 2. Verificar EC2 está corriendo
# 3. Verificar SG permite tráfico ALB → EC2
# 4. Invalidar cache si es necesario
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

### Terraform state corrupto

```bash
# 1. Descargar state de S3
aws s3 cp s3://zend-terraform-state/prod/terraform.tfstate ./backup.tfstate \
  --region mx-central-1

# 2. Verificar integridad
terraform state pull | jq . > /dev/null

# 3. Si es necesario, restaurar versión anterior
aws s3api list-object-versions \
  --bucket zend-terraform-state \
  --prefix prod/terraform.tfstate \
  --region mx-central-1
```