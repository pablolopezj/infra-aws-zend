# Solución de Problemas: State Lock en Terraform

## 🔒 ¿Qué es un State Lock?

Terraform usa un mecanismo de bloqueo (lock) para prevenir que múltiples operaciones modifiquen el estado al mismo tiempo. Esto protege tu infraestructura de corrupción.

## ⚠️ Error Común

```
Error: Error acquiring the state lock
Error message: ConditionalCheckFailedException
Lock Info:
  ID:        564de908-5bf7-5fce-7c89-378a4a825435
  Path:      zend-terraform-state/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       pablo@Pablos-MacBook-Pro.local
```

## ✅ Solución: Desbloquear el Estado

### Opción 1: Usar `terraform force-unlock` (Recomendado)

```bash
cd envs/prod

# Usar el Lock ID del mensaje de error
terraform force-unlock -force <LOCK_ID>
```

**Ejemplo**:
```bash
terraform force-unlock -force 564de908-5bf7-5fce-7c89-378a4a825435
```

### Opción 2: Eliminar el Lock Manualmente en DynamoDB

Si `force-unlock` no funciona:

```bash
# Ver el lock en DynamoDB
aws dynamodb scan \
  --table-name zend-terraform-locks \
  --region mx-central-1 \
  --filter-expression "LockID = :lockid" \
  --expression-attribute-values '{":lockid":{"S":"zend-terraform-state/prod/terraform.tfstate"}}'

# Eliminar el lock
aws dynamodb delete-item \
  --table-name zend-terraform-locks \
  --region mx-central-1 \
  --key '{"LockID":{"S":"zend-terraform-state/prod/terraform.tfstate"}}'
```

## 🔍 Verificar si hay un Lock Activo

### Ver locks en DynamoDB

```bash
aws dynamodb scan \
  --table-name zend-terraform-locks \
  --region mx-central-1
```

### Verificar procesos de Terraform

```bash
ps aux | grep terraform | grep -v grep
```

Si ves procesos activos, espera a que terminen antes de desbloquear.

## ⚠️ Cuándo Desbloquear

**✅ SEGURO desbloquear cuando:**
- La operación anterior se interrumpió (Ctrl+C, cierre de terminal)
- No hay procesos de Terraform ejecutándose
- Estás seguro de que no hay otra persona ejecutando Terraform

**❌ NO desbloquear cuando:**
- Hay una operación de Terraform en curso
- Otra persona del equipo está ejecutando Terraform
- No estás seguro del estado actual

## 🛡️ Prevenir Locks

### 1. Siempre espera a que termine `terraform apply`

No interrumpas operaciones de Terraform a menos que sea absolutamente necesario.

### 2. Usa timeouts en operaciones largas

```bash
# Si una operación tarda mucho, verifica el progreso
terraform apply -auto-approve -timeout=30m
```

### 3. Verifica antes de desbloquear

```bash
# Ver quién tiene el lock
aws dynamodb get-item \
  --table-name zend-terraform-locks \
  --key '{"LockID":{"S":"zend-terraform-state/prod/terraform.tfstate"}}' \
  --region mx-central-1
```

### 4. Usa CI/CD para evitar conflictos

Si trabajas en equipo, usa pipelines de CI/CD para ejecutar Terraform y evitar conflictos manuales.

## 📝 Comandos Útiles

### Ver información del lock actual

```bash
cd envs/prod
terraform force-unlock <LOCK_ID>
# (sin -force, te mostrará información del lock)
```

### Listar todos los locks en DynamoDB

```bash
aws dynamodb scan \
  --table-name zend-terraform-locks \
  --region mx-central-1 \
  --query 'Items[*].{LockID:LockID.S,Info:Info.S}' \
  --output table
```

### Limpiar locks antiguos (cuidado)

```bash
# Solo si estás seguro de que son locks huérfanos
aws dynamodb scan \
  --table-name zend-terraform-locks \
  --region mx-central-1 \
  --query 'Items[?contains(Info.S, `"Created":"2024-`)]' \
  --output json | \
  jq -r '.[].LockID.S' | \
  xargs -I {} aws dynamodb delete-item \
    --table-name zend-terraform-locks \
    --key "{\"LockID\":{\"S\":\"{}\"}}" \
    --region mx-central-1
```

## 🚨 Si el Problema Persiste

1. **Verifica permisos de DynamoDB**: Asegúrate de tener permisos para leer/escribir en la tabla
2. **Verifica conectividad**: Asegúrate de poder acceder a DynamoDB
3. **Revisa logs**: Revisa CloudWatch Logs para ver errores de DynamoDB
4. **Contacta al equipo**: Si trabajas en equipo, coordina antes de desbloquear

## 📚 Referencias

- [Terraform State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [AWS DynamoDB Backend](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)

---

**Última actualización**: 2024

