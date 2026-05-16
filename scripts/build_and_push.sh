#!/bin/bash

set -e

# Configuración
IMAGE_NAME=${IMAGE_NAME:-"mi-aplicacion"}
VERSION=${1:-latest}
DOCKERFILE=${2:-Dockerfile}
BUILD_CONTEXT=${3:-.}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cd envs/prod

# Obtener información de ECR
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")
REGISTRY_ID=$(terraform output -raw ecr_registry_id 2>/dev/null || echo "")

if [ -z "$ECR_REPO_URL" ] || [ "$ECR_REPO_URL" = "null" ]; then
    echo "❌ Error: ECR no está habilitado"
    echo "   Asegúrate de que enable_ecr = true en terraform.tfvars"
    echo "   Y ejecuta: terraform apply"
    exit 1
fi

cd "$SCRIPT_DIR"

echo "🔨 Construyendo imagen..."
echo "   Imagen: $IMAGE_NAME:$VERSION"
echo "   Dockerfile: $DOCKERFILE"
echo "   Contexto: $BUILD_CONTEXT"
echo ""

docker build -t $IMAGE_NAME:$VERSION -f $DOCKERFILE $BUILD_CONTEXT

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen"
    exit 1
fi

echo ""
echo "🏷️  Taggeando imagen para ECR..."
echo "   $IMAGE_NAME:$VERSION -> $ECR_REPO_URL:$VERSION"
docker tag $IMAGE_NAME:$VERSION $ECR_REPO_URL:$VERSION

echo ""
echo "🔐 Autenticando con ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo "❌ Error en la autenticación"
    exit 1
fi

echo ""
echo "📤 Subiendo imagen a ECR..."
docker push $ECR_REPO_URL:$VERSION

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Imagen subida exitosamente"
    echo "   URL: $ECR_REPO_URL:$VERSION"
    echo ""
    echo "💡 Para usar esta imagen:"
    echo "   docker pull $ECR_REPO_URL:$VERSION"
else
    echo ""
    echo "❌ Error al subir la imagen"
    exit 1
fi

