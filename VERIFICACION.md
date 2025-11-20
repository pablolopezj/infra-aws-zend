# Guía de Verificación de Infraestructura

Esta guía te ayudará a verificar que todos los recursos se crearon correctamente en AWS.

## 📋 Índice

1. [Verificar Backend (Bootstrap)](#1-verificar-backend-bootstrap)
2. [Verificar Infraestructura de Producción](#2-verificar-infraestructura-de-producción)
3. [Verificación con AWS CLI](#3-verificación-con-aws-cli)
4. [Verificación en Consola AWS](#4-verificación-en-consola-aws)
5. [Comandos de Verificación Rápida](#5-comandos-de-verificación-rápida)

---

## 1. Verificar Backend (Bootstrap)

### Con Terraform

```bash
cd envs/bootstrap

# Ver outputs del backend
terraform output

# Ver estado completo
terraform show

# Listar todos los recursos creados
terraform state list
```

**Outputs esperados:**
- `state_bucket = "zend-terraform-state"`
- `dynamodb_table = "zend-terraform-locks"`

### Con AWS CLI

```bash
# Verificar bucket S3
aws s3 ls | grep zend-terraform-state

# Ver detalles del bucket
aws s3api get-bucket-versioning --bucket zend-terraform-state

# Verificar tabla DynamoDB
aws dynamodb describe-table --table-name zend-terraform-locks --region mx-central-1

# Listar items en la tabla (debería estar vacía o con locks temporales)
aws dynamodb scan --table-name zend-terraform-locks --region mx-central-1
```

### En Consola AWS

1. **S3:**
   - Ve a **S3** → Busca `zend-terraform-state`
   - Verifica que tenga:
     - ✅ Versionado habilitado
     - ✅ Encriptación habilitada
     - ✅ Bloqueo de acceso público habilitado

2. **DynamoDB:**
   - Ve a **DynamoDB** → **Tables** → `zend-terraform-locks`
   - Verifica:
     - ✅ Clave primaria: `LockID` (String)
     - ✅ Billing mode: `PAY_PER_REQUEST`
     - ✅ Región: `mx-central-1`

---

## 2. Verificar Infraestructura de Producción

### Con Terraform

```bash
cd envs/prod

# Si es la primera vez, inicializa con el backend remoto
terraform init

# Ver outputs
terraform output

# Ver estado completo
terraform show

# Listar todos los recursos
terraform state list
```

**Outputs esperados:**
- `vpc_id = "vpc-xxxxxxxxx"`
- `public_subnet_id = "subnet-xxxxxxxxx"`
- `private_subnet_id = "subnet-xxxxxxxxx"`

### Con AWS CLI

```bash
# Obtener VPC ID desde Terraform
VPC_ID=$(cd envs/prod && terraform output -raw vpc_id)

# Verificar VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region mx-central-1

# Verificar subredes
PUBLIC_SUBNET=$(cd envs/prod && terraform output -raw public_subnet_id)
PRIVATE_SUBNET=$(cd envs/prod && terraform output -raw private_subnet_id)

aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET $PRIVATE_SUBNET --region mx-central-1

# Verificar Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region mx-central-1

# Verificar tablas de ruteo
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region mx-central-1
```

### En Consola AWS

1. **VPC:**
   - Ve a **VPC** → **Your VPCs**
   - Busca VPC con nombre: `zend-app-prod-mxc1-vpc`
   - Verifica:
     - ✅ CIDR: `10.0.0.0/16`
     - ✅ Estado: `available`

2. **Subredes:**
   - Ve a **VPC** → **Subnets**
   - Busca:
     - `zend-app-prod-mxc1-subnet-public-a` (CIDR: `10.0.1.0/24`, AZ: `mx-central-1a`)
     - `zend-app-prod-mxc1-subnet-private-a` (CIDR: `10.0.2.0/24`, AZ: `mx-central-1b`)

3. **Internet Gateway:**
   - Ve a **VPC** → **Internet Gateways**
   - Busca: `zend-app-prod-mxc1-igw`
   - Verifica que esté **Attached** a la VPC

4. **Route Tables:**
   - Ve a **VPC** → **Route Tables**
   - Deberías ver:
     - Tabla pública con ruta `0.0.0.0/0` → Internet Gateway
     - Tabla privada (sin ruta a Internet Gateway)

---

## 3. Verificación con AWS CLI

### Script de Verificación Completa

Crea un script `verify.sh`:

```bash
#!/bin/bash

echo "=== Verificando Backend ==="
echo "Bucket S3:"
aws s3 ls | grep zend-terraform-state || echo "❌ Bucket no encontrado"

echo -e "\nTabla DynamoDB:"
aws dynamodb describe-table --table-name zend-terraform-locks --region mx-central-1 2>/dev/null && echo "✅ Tabla existe" || echo "❌ Tabla no encontrada"

echo -e "\n=== Verificando Infraestructura ==="
cd envs/prod

VPC_ID=$(terraform output -raw vpc_id 2>/dev/null)
if [ -z "$VPC_ID" ]; then
    echo "❌ No se puede obtener VPC ID. Ejecuta 'terraform init' primero."
    exit 1
fi

echo "VPC ID: $VPC_ID"
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region mx-central-1 --query 'Vpcs[0].{ID:VpcId,CIDR:CidrBlock,State:State}' --output table

echo -e "\nSubredes:"
PUBLIC_SUBNET=$(terraform output -raw public_subnet_id)
PRIVATE_SUBNET=$(terraform output -raw private_subnet_id)

aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET $PRIVATE_SUBNET --region mx-central-1 \
    --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`].Value|[0]}' \
    --output table

echo -e "\nInternet Gateway:"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region mx-central-1 \
    --query 'InternetGateways[*].{ID:InternetGatewayId,State:Attachments[0].State}' \
    --output table

echo -e "\n✅ Verificación completada"
```

### Ejecutar el script

```bash
chmod +x verify.sh
./verify.sh
```

---

## 4. Verificación en Consola AWS

### Checklist Visual

#### Backend (Bootstrap)
- [ ] **S3**: Bucket `zend-terraform-state` existe
  - Versionado: ✅ Enabled
  - Encriptación: ✅ Enabled (SSE-S3)
  - Public access: ✅ Blocked
  
- [ ] **DynamoDB**: Tabla `zend-terraform-locks` existe
  - Clave primaria: `LockID`
  - Billing: PAY_PER_REQUEST
  - Región: mx-central-1

#### Infraestructura (Prod)
- [ ] **VPC**: `zend-app-prod-mxc1-vpc`
  - CIDR: 10.0.0.0/16
  - Estado: available
  
- [ ] **Subred Pública**: `zend-app-prod-mxc1-subnet-public-a`
  - CIDR: 10.0.1.0/24
  - AZ: mx-central-1a
  - Auto-assign IP: ✅ Enabled
  
- [ ] **Subred Privada**: `zend-app-prod-mxc1-subnet-private-a`
  - CIDR: 10.0.2.0/24
  - AZ: mx-central-1b
  
- [ ] **Internet Gateway**: `zend-app-prod-mxc1-igw`
  - Estado: Attached
  - VPC: zend-app-prod-mxc1-vpc
  
- [ ] **Route Tables**:
  - Tabla pública: Ruta 0.0.0.0/0 → IGW
  - Tabla privada: Sin ruta a IGW

---

## 5. Comandos de Verificación Rápida

### Todo en uno (Terraform)

```bash
# Backend
cd envs/bootstrap && terraform output && terraform state list

# Infraestructura
cd ../prod && terraform output && terraform state list
```

### Todo en uno (AWS CLI)

```bash
# Backend
echo "=== S3 Bucket ===" && \
aws s3 ls | grep zend-terraform-state && \
echo "=== DynamoDB Table ===" && \
aws dynamodb describe-table --table-name zend-terraform-locks --region mx-central-1 --query 'Table.TableName' && \
echo "=== VPC ===" && \
cd envs/prod && \
VPC_ID=$(terraform output -raw vpc_id) && \
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region mx-central-1 --query 'Vpcs[0].VpcId' && \
echo "✅ Todos los recursos verificados"
```

### Verificar Estado de Terraform

```bash
# Verificar que el estado está en S3 (no local)
cd envs/prod
terraform state list  # Si funciona, el backend está configurado correctamente

# Verificar que el estado está sincronizado
terraform refresh  # Actualiza el estado con el estado real de AWS
```

---

## 🚨 Solución de Problemas

### Error: "Backend initialization required"
```bash
cd envs/prod
terraform init
```

### Error: "Bucket does not exist"
```bash
# Verifica que el bootstrap se ejecutó correctamente
cd envs/bootstrap
terraform state list
```

### Error: "Access Denied"
```bash
# Verifica tus credenciales de AWS
aws sts get-caller-identity
```

### Estado desincronizado
```bash
# Refresca el estado con AWS
terraform refresh
```

---

## 📊 Verificación de Costos

Para verificar que no hay costos inesperados:

```bash
# Ver recursos creados (gratuitos o de bajo costo)
aws ec2 describe-vpcs --region mx-central-1 --query 'Vpcs[*].VpcId'
aws s3 ls
aws dynamodb list-tables --region mx-central-1
```

**Recursos creados (costo estimado):**
- VPC: **Gratis**
- Subredes: **Gratis**
- Internet Gateway: **Gratis**
- Route Tables: **Gratis**
- S3 Bucket: **~$0.023/GB/mes** (primeros 50TB)
- DynamoDB: **Gratis** (dentro del tier gratuito para este uso)

---

**Última actualización**: 2024

