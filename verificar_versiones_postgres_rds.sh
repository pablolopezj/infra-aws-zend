#!/bin/bash
# Script para verificar qué versiones de PostgreSQL están disponibles en RDS
# para una región específica de AWS

REGION=${1:-"mx-central-1"}

echo "=== Verificando versiones de PostgreSQL disponibles en RDS ==="
echo "Región: $REGION"
echo ""

# Verificar versiones 9.6
echo "📋 Versiones PostgreSQL 9.6:"
aws rds describe-db-engine-versions \
    --engine postgres \
    --region "$REGION" \
    --output json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    versions = data.get('DBEngineVersions', [])
    target_96 = [v['EngineVersion'] for v in versions if v['EngineVersion'].startswith('9.6')]
    if target_96:
        for v in sorted(set(target_96)):
            print(f\"  ✓ {v}\")
    else:
        print(\"  ✗ No disponibles\")
except Exception as e:
    print(f\"  Error: {e}\")
" || echo "  ✗ Error al consultar"

echo ""

# Verificar versiones 10.x
echo "📋 Versiones PostgreSQL 10.x:"
aws rds describe-db-engine-versions \
    --engine postgres \
    --region "$REGION" \
    --output json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    versions = data.get('DBEngineVersions', [])
    target_10 = [v['EngineVersion'] for v in versions if v['EngineVersion'].startswith('10.')]
    if target_10:
        for v in sorted(set(target_10)):
            print(f\"  ✓ {v}\")
    else:
        print(\"  ✗ No disponibles\")
except Exception as e:
    print(f\"  Error: {e}\")
" || echo "  ✗ Error al consultar"

echo ""

# Mostrar versión más antigua disponible
echo "📋 Versión más antigua disponible:"
aws rds describe-db-engine-versions \
    --engine postgres \
    --region "$REGION" \
    --output json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    versions = data.get('DBEngineVersions', [])
    if versions:
        all_versions = list(set([v['EngineVersion'] for v in versions]))
        # Ordenar por número de versión principal
        def sort_key(v):
            parts = v.split('.')
            try:
                major = int(parts[0])
                minor = int(parts[1].split('-')[0]) if len(parts) > 1 else 0
                return (major, minor)
            except:
                return (999, 999)
        all_versions.sort(key=sort_key)
        print(f\"  {all_versions[0]}\")
        print(f\"  (Total de versiones disponibles: {len(all_versions)})\")
    else:
        print(\"  No se encontraron versiones\")
except Exception as e:
    print(f\"  Error: {e}\")
" || echo "  ✗ Error al consultar"

echo ""

# Mostrar algunas versiones recientes disponibles
echo "📋 Algunas versiones recientes disponibles:"
aws rds describe-db-engine-versions \
    --engine postgres \
    --region "$REGION" \
    --output json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    versions = data.get('DBEngineVersions', [])
    if versions:
        all_versions = list(set([v['EngineVersion'] for v in versions]))
        def sort_key(v):
            parts = v.split('.')
            try:
                major = int(parts[0])
                minor = int(parts[1].split('-')[0]) if len(parts) > 1 else 0
                return (major, minor)
            except:
                return (999, 999)
        all_versions.sort(key=sort_key)
        recent = all_versions[-5:]  # Últimas 5 versiones
        for v in recent:
            print(f\"  ✓ {v}\")
except Exception as e:
    print(f\"  Error: {e}\")
" || echo "  ✗ Error al consultar"

echo ""
echo "💡 Nota: Si las versiones 9.6 o 10 no están disponibles,"
echo "   significa que AWS las ha descontinuado en esta región."
echo "   Deberás usar una versión más reciente de PostgreSQL."

