# Guía de Uso de ECR (Elastic Container Registry)

Esta guía te ayudará a usar el repositorio ECR creado con Terraform para subir y gestionar tus imágenes Docker.

## 📋 Índice

1. [Habilitar ECR en Terraform](#1-habilitar-ecr-en-terraform)
2. [Obtener Información del Repositorio](#2-obtener-información-del-repositorio)
3. [Autenticarse con ECR](#3-autenticarse-con-ecr)
4. [Construir y Subir Imágenes](#4-construir-y-subir-imágenes)
5. [Listar y Gestionar Imágenes](#5-listar-y-gestionar-imágenes)
6. [Pull de Imágenes](#6-pull-de-imágenes)
7. [Integración con CI/CD](#7-integración-con-cicd)
8. [Solución de Problemas](#8-solución-de-problemas)

---

## 1. Habilitar ECR en Terraform

### Configurar Variables

Edita `envs/prod/terraform.tfvars` y agrega:

```hcl
# Habilitar ECR
enable_ecr = true

# Opcional: Personalizar nombre del repositorio
# ecr_repository_name = "mi-aplicacion"

# Opcional: Configuración avanzada
# ecr_image_tag_mutability = "IMMUTABLE"  # o "MUTABLE"
# ecr_scan_on_push = true
# ecr_max_image_count = 10
# ecr_max_image_age_days = 30
```

### Aplicar Cambios

```bash
cd envs/prod
terraform init
terraform plan
terraform apply
```

---

## 2. Obtener Información del Repositorio

### Obtener URL del Repositorio

```bash
cd envs/prod

# Obtener URL completa del repositorio
terraform output ecr_repository_url

# Obtener nombre del repositorio
terraform output ecr_repository_name

# Obtener ARN del repositorio
terraform output ecr_repository_arn

# Obtener Registry ID
terraform output ecr_registry_id
```

### Guardar URL en Variable

```bash
# Guardar URL en variable de entorno
export ECR_REPO_URL=$(cd envs/prod && terraform output -raw ecr_repository_url)
echo "ECR Repository URL: $ECR_REPO_URL"
```

---

## 3. Autenticarse con ECR

### Autenticación con AWS CLI

ECR requiere autenticación antes de poder hacer push/pull de imágenes.

```bash
# Obtener región
REGION=$(cd envs/prod && terraform output -raw aws_region || echo "mx-central-1")

# Obtener Registry ID
REGISTRY_ID=$(cd envs/prod && terraform output -raw ecr_registry_id)

# Autenticarse con ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com
```

### Script de Autenticación

Crea un script `autenticar_ecr.sh`:

```bash
#!/bin/bash

cd envs/prod

REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")
REGISTRY_ID=$(terraform output -raw ecr_registry_id)

if [ -z "$REGISTRY_ID" ] || [ "$REGISTRY_ID" = "null" ]; then
    echo "❌ Error: ECR no está habilitado o no se encontró el registry ID"
    exit 1
fi

echo "🔐 Autenticando con ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com

if [ $? -eq 0 ]; then
    echo "✅ Autenticación exitosa"
else
    echo "❌ Error en la autenticación"
    exit 1
fi
```

Hazlo ejecutable:

```bash
chmod +x autenticar_ecr.sh
```

---

## 4. Construir y Subir Imágenes

### Construir Imagen Docker

```bash
# Construir imagen localmente
docker build -t mi-aplicacion:latest .

# O con un tag específico
docker build -t mi-aplicacion:v1.0.0 .
```

### Taggear Imagen para ECR

```bash
# Obtener URL del repositorio
ECR_REPO_URL=$(cd envs/prod && terraform output -raw ecr_repository_url)

# Taggear imagen con la URL de ECR
docker tag mi-aplicacion:latest $ECR_REPO_URL:latest
docker tag mi-aplicacion:v1.0.0 $ECR_REPO_URL:v1.0.0
```

### Subir Imagen a ECR

```bash
# Asegúrate de estar autenticado primero
./autenticar_ecr.sh

# Subir imagen
docker push $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:v1.0.0
```

### Script Completo de Build y Push

Crea un script `build_and_push.sh`:

```bash
#!/bin/bash

set -e

# Configuración
IMAGE_NAME="mi-aplicacion"
VERSION=${1:-latest}
DOCKERFILE=${2:-Dockerfile}

cd envs/prod

# Obtener URL del repositorio
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")
REGISTRY_ID=$(terraform output -raw ecr_registry_id)

if [ -z "$ECR_REPO_URL" ] || [ "$ECR_REPO_URL" = "null" ]; then
    echo "❌ Error: ECR no está habilitado"
    exit 1
fi

echo "🔨 Construyendo imagen..."
cd ../..
docker build -t $IMAGE_NAME:$VERSION -f $DOCKERFILE .

echo "🏷️  Taggeando imagen para ECR..."
docker tag $IMAGE_NAME:$VERSION $ECR_REPO_URL:$VERSION

echo "🔐 Autenticando con ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com

echo "📤 Subiendo imagen a ECR..."
docker push $ECR_REPO_URL:$VERSION

echo "✅ Imagen subida exitosamente: $ECR_REPO_URL:$VERSION"
```

Uso:

```bash
chmod +x build_and_push.sh

# Subir con tag "latest"
./build_and_push.sh

# Subir con tag específico
./build_and_push.sh v1.0.0

# Especificar Dockerfile
./build_and_push.sh v1.0.0 Dockerfile.prod
```

---

## 5. Listar y Gestionar Imágenes

### Listar Imágenes en el Repositorio

```bash
# Obtener información
cd envs/prod
ECR_REPO_NAME=$(terraform output -raw ecr_repository_name)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")

# Listar todas las imágenes
aws ecr list-images \
    --repository-name $ECR_REPO_NAME \
    --region $REGION

# Listar con más detalles
aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --region $REGION \
    --query 'imageDetails[*].{Tag:imageTags[0],Pushed:imagePushedAt,Size:imageSizeInBytes}' \
    --output table
```

### Ver Detalles de una Imagen Específica

```bash
# Ver detalles de una imagen con tag específico
aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --image-ids imageTag=latest \
    --region $REGION
```

### Eliminar Imágenes

```bash
# Eliminar una imagen específica
aws ecr batch-delete-image \
    --repository-name $ECR_REPO_NAME \
    --image-ids imageTag=v1.0.0 \
    --region $REGION

# Eliminar múltiples imágenes
aws ecr batch-delete-image \
    --repository-name $ECR_REPO_NAME \
    --image-ids imageTag=old-tag1 imageTag=old-tag2 \
    --region $REGION
```

### Ver Resultados de Escaneo de Seguridad

Si `scan_on_push` está habilitado, puedes ver los resultados del escaneo:

```bash
# Ver resultados de escaneo
aws ecr describe-image-scan-findings \
    --repository-name $ECR_REPO_NAME \
    --image-id imageTag=latest \
    --region $REGION
```

---

## 6. Pull de Imágenes

### Descargar Imagen desde ECR

```bash
# Autenticarse primero
./autenticar_ecr.sh

# Obtener URL del repositorio
ECR_REPO_URL=$(cd envs/prod && terraform output -raw ecr_repository_url)

# Descargar imagen
docker pull $ECR_REPO_URL:latest
docker pull $ECR_REPO_URL:v1.0.0
```

### Ejecutar Contenedor desde ECR

```bash
# Ejecutar contenedor
docker run -d -p 8080:80 --name mi-app $ECR_REPO_URL:latest

# Ver logs
docker logs mi-app

# Detener contenedor
docker stop mi-app
docker rm mi-app
```

---

## 7. Integración con CI/CD

### GitHub Actions

Ejemplo de workflow para GitHub Actions:

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [ main ]

env:
  AWS_REGION: mx-central-1
  ECR_REPOSITORY: zend-app-prod-mxc1-app

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

### GitLab CI

Ejemplo de `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

variables:
  AWS_REGION: mx-central-1
  ECR_REPOSITORY: zend-app-prod-mxc1-app

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache aws-cli
    - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
  script:
    - docker build -t $ECR_REPOSITORY:$CI_COMMIT_SHA .
    - docker push $ECR_REPOSITORY:$CI_COMMIT_SHA
    - docker tag $ECR_REPOSITORY:$CI_COMMIT_SHA $ECR_REPOSITORY:latest
    - docker push $ECR_REPOSITORY:latest
  only:
    - main
```

---

## 8. Solución de Problemas

### Error: "no basic auth credentials"

**Causa:** No estás autenticado con ECR.

**Solución:**
```bash
./autenticar_ecr.sh
```

### Error: "repository does not exist"

**Causa:** El repositorio no existe o el nombre es incorrecto.

**Solución:**
```bash
# Verificar que ECR está habilitado
cd envs/prod
terraform output ecr_repository_name

# Verificar que el repositorio existe
aws ecr describe-repositories --region mx-central-1
```

### Error: "denied: Your authorization token has expired"

**Causa:** El token de autenticación expiró (válido por 12 horas).

**Solución:**
```bash
# Re-autenticarse
./autenticar_ecr.sh
```

### Error: "image tag already exists" (con IMMUTABLE)

**Causa:** Estás intentando hacer push de una imagen con un tag que ya existe y el repositorio está configurado como IMMUTABLE.

**Solución:**
- Usa un tag diferente (por ejemplo, incluye el commit SHA)
- O cambia `ecr_image_tag_mutability` a `MUTABLE` en Terraform

### Verificar Estado del Repositorio

```bash
cd envs/prod
ECR_REPO_NAME=$(terraform output -raw ecr_repository_name)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")

# Ver detalles del repositorio
aws ecr describe-repositories \
    --repository-names $ECR_REPO_NAME \
    --region $REGION
```

### Ver Política de Lifecycle

```bash
# Ver política de lifecycle activa
aws ecr get-lifecycle-policy \
    --repository-name $ECR_REPO_NAME \
    --region $REGION
```

---

## 📝 Comandos Útiles

```bash
# Autenticarse
aws ecr get-login-password --region mx-central-1 | docker login --username AWS --password-stdin <REGISTRY_ID>.dkr.ecr.mx-central-1.amazonaws.com

# Listar repositorios
aws ecr describe-repositories --region mx-central-1

# Listar imágenes
aws ecr list-images --repository-name <REPO_NAME> --region mx-central-1

# Ver detalles de imagen
aws ecr describe-images --repository-name <REPO_NAME> --image-ids imageTag=latest --region mx-central-1

# Eliminar imagen
aws ecr batch-delete-image --repository-name <REPO_NAME> --image-ids imageTag=<TAG> --region mx-central-1
```

---

**Última actualización**: 2024

