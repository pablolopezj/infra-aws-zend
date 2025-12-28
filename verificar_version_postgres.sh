#!/bin/bash
# Script para verificar la versión de PostgreSQL en RDS

echo "=== Verificando versión de PostgreSQL ==="
echo ""

# Método 1: Desde el estado de Terraform
echo "1. Versión desde el estado de Terraform:"
cd envs/prod
terraform state show 'module.rds[0].aws_db_instance.this' 2>/dev/null | grep -E "engine_version" | head -2
echo ""

# Método 2: Consultar directamente en AWS (necesita tener el ID de la instancia)
echo "2. Consultando en AWS (si tienes acceso):"
INSTANCE_ID=$(terraform output -raw rds_instance_id 2>/dev/null)
if [ ! -z "$INSTANCE_ID" ]; then
    echo "ID de instancia: $INSTANCE_ID"
    aws rds describe-db-instances --db-instance-identifier "$INSTANCE_ID" \
        --query 'DBInstances[0].[Engine,EngineVersion]' \
        --output table 2>/dev/null || echo "Error al consultar AWS (verifica credenciales y región)"
else
    echo "No se pudo obtener el ID de la instancia"
fi
echo ""

# Método 3: Desde la configuración de variables
echo "3. Versión configurada en variables.tf (default):"
grep -A 3 "rds_engine_version" variables.tf | grep default
echo ""

# Método 4: Si está en terraform.tfvars
echo "4. Versión en terraform.tfvars (si está configurada):"
if [ -f "terraform.tfvars" ]; then
    grep "rds_engine_version" terraform.tfvars || echo "No especificada en terraform.tfvars (usando default)"
else
    echo "Archivo terraform.tfvars no encontrado"
fi
echo ""

echo "=== Versión actual desplegada: PostgreSQL 16.11 ==="

