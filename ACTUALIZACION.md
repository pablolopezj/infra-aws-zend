# Guía de Actualización - Recursos de Seguridad

Esta guía explica cómo aplicar los nuevos recursos de seguridad (Security Groups, NACLs, VPC Endpoints) a tu infraestructura existente en AWS.

## 📋 Resumen de Cambios

Se agregaron los siguientes recursos al módulo `network`:
- ✅ Security Groups (público y privado)
- ✅ Network ACLs (público y privado)
- ✅ VPC Endpoints para S3 y DynamoDB

## ⚠️ Importante: NO necesitas ejecutar nada en `bootstrap`

**Razón**: El entorno `bootstrap` solo crea el backend de Terraform (S3 + DynamoDB). Los cambios están en el módulo `network` que se usa en `prod`.

## 🚀 Pasos para Aplicar los Cambios

### Paso 1: Verificar que el Backend Existe

```bash
cd envs/bootstrap
terraform state list
```

**Salida esperada**: Deberías ver recursos de S3 y DynamoDB. Si los ves, el backend está listo.

### Paso 2: Navegar al Entorno de Producción

```bash
cd ../prod
```

### Paso 3: Inicializar Terraform (si es necesario)

Si es la primera vez o cambiaste el backend:

```bash
terraform init
```

Si ya tienes el backend configurado y solo actualizaste el código:

```bash
terraform init -upgrade
```

### Paso 4: Ver el Plan de Ejecución

**Este es el paso más importante** - te muestra exactamente qué se va a crear:

```bash
terraform plan
```

**Recursos que deberías ver en el plan**:
- `aws_security_group.public` (nuevo)
- `aws_security_group.private` (nuevo)
- `aws_network_acl.public` (nuevo)
- `aws_network_acl.private` (nuevo)
- `aws_network_acl_association.public` (nuevo)
- `aws_network_acl_association.private` (nuevo)
- `aws_vpc_endpoint.s3` (nuevo, si `enable_vpc_endpoints = true`)
- `aws_vpc_endpoint.dynamodb` (nuevo, si `enable_vpc_endpoints = true`)
- `data.aws_region.current` (nuevo)

**⚠️ Verifica que NO se vayan a destruir recursos existentes** (VPC, subredes, etc.)

### Paso 5: Aplicar los Cambios

Si el plan se ve correcto:

```bash
terraform apply
```

Terraform te pedirá confirmación. Revisa el resumen y escribe `yes` para continuar.

### Paso 6: Verificar los Outputs

Después de aplicar, verifica que los nuevos recursos se crearon:

```bash
terraform output
```

Deberías ver:
- `public_security_group_id`
- `private_security_group_id`
- `public_network_acl_id`
- `private_network_acl_id`
- `s3_vpc_endpoint_id`
- `dynamodb_vpc_endpoint_id`

## 📊 Comandos Rápidos (Todo en Uno)

```bash
# Desde la raíz del proyecto
cd envs/prod

# Inicializar (si es necesario)
terraform init -upgrade

# Ver plan
terraform plan

# Aplicar (después de revisar el plan)
terraform apply

# Verificar outputs
terraform output
```

## 🔍 Verificación en AWS Console

Después de aplicar, verifica en la consola de AWS:

### Security Groups
1. Ve a **EC2** → **Security Groups**
2. Busca: `zend-app-prod-mxc1-sg-public` y `zend-app-prod-mxc1-sg-private`
3. Verifica las reglas de entrada/salida

### Network ACLs
1. Ve a **VPC** → **Network ACLs**
2. Busca: `zend-app-prod-mxc1-nacl-public` y `zend-app-prod-mxc1-nacl-private`
3. Verifica las reglas

### VPC Endpoints
1. Ve a **VPC** → **Endpoints**
2. Busca: `zend-app-prod-mxc1-vpc-endpoint-s3` y `zend-app-prod-mxc1-vpc-endpoint-dynamodb`
3. Verifica que el estado sea `available`

## ⚠️ Posibles Problemas y Soluciones

### Error: "Backend initialization required"
```bash
terraform init
```

### Error: "Module source changed"
```bash
terraform init -upgrade
```

### Error: "Resource already exists"
Esto puede pasar si los recursos ya existen. Verifica en AWS Console o usa:
```bash
terraform import <resource_type>.<name> <resource_id>
```

### Warning: "Deprecated parameter dynamodb_table"
Este warning es informativo. El backend sigue funcionando. Puedes actualizar `providers.tf` más tarde para usar `use_lockfile` en lugar de `dynamodb_table`.

## 📝 Notas Importantes

1. **No hay downtime**: Los nuevos recursos se agregan sin afectar los existentes
2. **Costo**: Security Groups y NACLs son gratuitos. VPC Endpoints Gateway (S3/DynamoDB) también son gratuitos
3. **Compatibilidad**: Los recursos existentes (VPC, subredes) no se modifican
4. **Rollback**: Si necesitas revertir, puedes comentar los nuevos recursos y ejecutar `terraform apply` nuevamente

## 🔄 Próximos Pasos Después de Aplicar

Una vez aplicados los cambios, puedes:

1. **Asociar Security Groups a tus instancias EC2**:
   ```terraform
   resource "aws_instance" "example" {
     vpc_security_group_ids = [module.network.public_security_group_id]
     subnet_id              = module.network.public_subnet_id
   }
   ```

2. **Usar los outputs en otros módulos**:
   ```terraform
   module "database" {
     source = "../modules/database"
     security_group_id = module.network.private_security_group_id
     subnet_id         = module.network.private_subnet_id
   }
   ```

3. **Verificar que los VPC Endpoints funcionan**:
   - El tráfico a S3 y DynamoDB ahora debería usar los endpoints
   - Verifica en CloudWatch que no hay transferencia de datos saliente para estos servicios

---

**Última actualización**: 2024

