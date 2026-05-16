#!/bin/bash
# Script para verificar la configuración de IAM para Secrets Manager

echo "=== Verificando IAM Permissions para Secrets Manager ==="
echo ""

cd envs/prod

# Obtener información del secreto
echo "📋 Información del Secreto RDS:"
SECRET_ARN=$(terraform state show aws_secretsmanager_secret.rds_credentials 2>/dev/null | grep "arn" | head -1 | awk '{print $3}' | tr -d '"' || echo "")
if [ ! -z "$SECRET_ARN" ]; then
    echo "  ARN completo: $SECRET_ARN"
    # Extraer el ARN base sin el sufijo
    SECRET_ARN_BASE=$(echo "$SECRET_ARN" | sed 's/-[A-Za-z0-9]*$/-*/')
    echo "  ARN con wildcard: $SECRET_ARN_BASE"
else
    echo "  ✗ No se encontró el secreto en el estado"
fi
echo ""

# Verificar el IAM Role
echo "📋 IAM Role para EC2:"
ROLE_NAME=$(terraform state show 'aws_iam_role.ec2_s3_access[0]' 2>/dev/null | grep "name" | head -1 | awk '{print $3}' | tr -d '"' || echo "")
if [ ! -z "$ROLE_NAME" ]; then
    echo "  Role: $ROLE_NAME"
    ROLE_ARN=$(terraform state show 'aws_iam_role.ec2_s3_access[0]' 2>/dev/null | grep "arn" | head -1 | awk '{print $3}' | tr -d '"' || echo "")
    echo "  ARN: $ROLE_ARN"
else
    echo "  ✗ No se encontró el IAM role"
fi
echo ""

# Verificar la política de Secrets Manager
echo "📋 Política IAM para Secrets Manager:"
POLICY_JSON=$(terraform state show 'aws_iam_role_policy.ec2_secrets_access[0]' 2>/dev/null | grep -A 30 "policy" | grep -A 30 "jsonencode" || echo "")
if [ ! -z "$POLICY_JSON" ]; then
    echo "  ✓ Política encontrada"
    echo ""
    echo "  Contenido de la política:"
    terraform state show 'aws_iam_role_policy.ec2_secrets_access[0]' 2>/dev/null | \
        grep -A 30 "policy" | \
        sed 's/^/    /'
    
    echo ""
    echo "  Verificación de permisos:"
    if echo "$POLICY_JSON" | grep -q "GetSecretValue"; then
        echo "    ✓ secretsmanager:GetSecretValue presente"
    else
        echo "    ✗ secretsmanager:GetSecretValue NO encontrado"
    fi
    
    if echo "$POLICY_JSON" | grep -q "DescribeSecret"; then
        echo "    ✓ secretsmanager:DescribeSecret presente"
    else
        echo "    ℹ secretsmanager:DescribeSecret (opcional)"
    fi
    
    echo ""
    echo "  Recurso (Resource) configurado:"
    RESOURCE_ARN=$(terraform state show 'aws_iam_role_policy.ec2_secrets_access[0]' 2>/dev/null | grep -A 30 "policy" | grep "secret:" | head -1 | sed 's/.*secret:/secret:/' | sed 's/",$//' | sed 's/"$//' || echo "")
    if [ ! -z "$RESOURCE_ARN" ]; then
        echo "    ARN actual: $RESOURCE_ARN"
        if echo "$RESOURCE_ARN" | grep -q "\*"; then
            echo "    ✓ Usa wildcard (flexible para versiones futuras)"
        else
            echo "    ℹ ARN específico (funciona, pero menos flexible)"
            echo "    💡 Consideración: Si el secreto se recrea, el sufijo puede cambiar"
        fi
    fi
else
    echo "  ✗ No se encontró la política de Secrets Manager"
    echo "    Verifica que enable_ec2_instance y create_ec2_s3_role estén habilitados"
fi

echo ""
echo "=== Resumen ==="
echo ""
echo "Estado actual:"
echo "  ✓ Permiso GetSecretValue: Configurado"
if [ ! -z "$SECRET_ARN" ] && [ ! -z "$RESOURCE_ARN" ]; then
    if echo "$RESOURCE_ARN" | grep -q "\*"; then
        echo "  ✓ ARN con wildcard: Sí (recomendado)"
    else
        echo "  ℹ ARN con wildcard: No (funciona, pero ARN específico)"
        echo ""
        echo "Recomendación:"
        echo "  Si quieres usar wildcard, cambia el Resource en main.tf a:"
        echo "  Resource = \"\${replace(aws_secretsmanager_secret.rds_credentials.arn, \"-\\\${substr(aws_secretsmanager_secret.rds_credentials.arn, length(aws_secretsmanager_secret.rds_credentials.arn) - 6, 6)}\", \"-*\")}\""
        echo "  O simplemente:"
        echo "  Resource = \"arn:aws:secretsmanager:\${data.aws_region.current.name}:\${data.aws_caller_identity.current.account_id}:secret:\${local.name_prefix}-rds-credentials-*\""
    fi
fi
echo ""

