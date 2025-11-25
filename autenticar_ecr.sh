#!/bin/bash

set -e

cd envs/prod

REGION=$(terraform output -raw aws_region 2>/dev/null || echo "mx-central-1")
REGISTRY_ID=$(terraform output -raw ecr_registry_id 2>/dev/null || echo "")

if [ -z "$REGISTRY_ID" ] || [ "$REGISTRY_ID" = "null" ]; then
    echo "❌ Error: ECR no está habilitado o no se encontró el registry ID"
    echo "   Asegúrate de que enable_ecr = true en terraform.tfvars"
    echo "   Y ejecuta: terraform apply"
    exit 1
fi

echo "🔐 Autenticando con ECR..."
echo "   Registry: $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com"
echo "   Región: $REGION"
echo ""

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_ID.dkr.ecr.$REGION.amazonaws.com

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Autenticación exitosa"
    echo "   Ahora puedes hacer push/pull de imágenes"
else
    echo ""
    echo "❌ Error en la autenticación"
    echo "   Verifica tus credenciales de AWS: aws configure"
    exit 1
fi

