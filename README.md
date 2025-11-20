# Infraestructura AWS - Zend App

Infraestructura como código (IaC) para desplegar recursos de red en AWS usando Terraform. Este proyecto está diseñado para desplegarse en la región `mx-central-1` (México Central).

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Prerrequisitos](#prerrequisitos)
- [Flujo de Trabajo](#flujo-de-trabajo)
- [Arquitectura](#arquitectura)
- [Variables Importantes](#variables-importantes)
- [Comandos Comunes](#comandos-comunes)

## 📖 Descripción

Este proyecto gestiona la infraestructura de red para la aplicación Zend en AWS, incluyendo:

- **VPC** con subredes públicas y privadas
- **Internet Gateway** para conectividad pública
- **Tablas de ruteo** para subredes públicas y privadas
- **Backend remoto** (S3 + DynamoDB) para gestión segura del estado de Terraform

## 📁 Estructura del Proyecto

```
infra-aws-zend/
├── envs/
│   ├── bootstrap/          # Entorno para crear el backend de Terraform
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   └── outputs.tf
│   └── prod/               # Entorno de producción
│       ├── main.tf
│       ├── variables.tf
│       ├── providers.tf
│       └── outputs.tf
└── modules/
    ├── network/            # Módulo de red (VPC, subredes, IGW, etc.)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── state_backend/      # Módulo para backend de Terraform (S3 + DynamoDB)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔧 Prerrequisitos

Antes de comenzar, asegúrate de tener:

1. **Terraform** instalado (versión >= 1.5.0)
   ```bash
   terraform version
   ```

2. **AWS CLI** configurado con credenciales válidas
   ```bash
   aws configure
   ```

3. **Permisos de AWS** suficientes para crear:
   - Buckets S3
   - Tablas DynamoDB
   - Recursos de VPC (VPC, Subnets, Internet Gateway, Route Tables)

## 🚀 Flujo de Trabajo

### Paso 1: Crear el Backend de Terraform (Bootstrap)

**⚠️ IMPORTANTE:** Este paso debe ejecutarse **SOLO UNA VEZ** antes de usar el entorno de producción. El backend de Terraform (S3 + DynamoDB) debe existir antes de que el entorno `prod` pueda usar el estado remoto.

1. Navega al directorio bootstrap:
   ```bash
   cd envs/bootstrap
   ```

2. Inicializa Terraform (usando backend local):
   ```bash
   terraform init
   ```

3. Revisa el plan de ejecución:
   ```bash
   terraform plan
   ```

4. Aplica los cambios para crear el bucket S3 y la tabla DynamoDB:
   ```bash
   terraform apply
   ```

   Esto creará:
   - **Bucket S3**: `zend-terraform-state` (con versionado y encriptación)
   - **Tabla DynamoDB**: `zend-terraform-locks` (para bloqueo de estado)

5. Verifica que los recursos se crearon correctamente:
   ```bash
   terraform output
   ```

### Paso 2: Configurar el Entorno de Producción

Una vez que el backend está creado, puedes usar el entorno de producción:

1. Navega al directorio de producción:
   ```bash
   cd ../prod
   ```

2. Inicializa Terraform con el backend remoto:
   ```bash
   terraform init
   ```

   Si ya tenías un estado local, Terraform te preguntará si quieres migrar. Responde `yes` para migrar el estado al backend remoto.

3. Revisa el plan de ejecución:
   ```bash
   terraform plan
   ```

4. Aplica los cambios para crear la infraestructura de red:
   ```bash
   terraform apply
   ```

   Esto creará:
   - VPC con CIDR `10.0.0.0/16`
   - Subred pública en `mx-central-1a` con CIDR `10.0.1.0/24`
   - Subred privada en `mx-central-1b` con CIDR `10.0.2.0/24`
   - Internet Gateway
   - Tablas de ruteo para subredes públicas y privadas

5. Verifica los outputs:
   ```bash
   terraform output
   ```

## 🏗️ Arquitectura

### Recursos de Red Creados

```
┌─────────────────────────────────────────────────┐
│                    VPC                          │
│            (10.0.0.0/16)                       │
│                                                 │
│  ┌──────────────────┐  ┌──────────────────┐    │
│  │  Subred Pública │  │ Subred Privada  │    │
│  │  (10.0.1.0/24)  │  │  (10.0.2.0/24)  │    │
│  │  mx-central-1a  │  │  mx-central-1b  │    │
│  │                 │  │                  │    │
│  │  Route Table    │  │  Route Table     │    │
│  │  (Pública)      │  │  (Privada)       │    │
│  └────────┬────────┘  └──────────────────┘    │
│           │                                     │
└───────────┼─────────────────────────────────────┘
            │
            ▼
    ┌───────────────┐
    │ Internet      │
    │ Gateway       │
    └───────────────┘
```

### Backend de Terraform

- **S3 Bucket**: Almacena el estado de Terraform con versionado habilitado
- **DynamoDB Table**: Proporciona bloqueo de estado para prevenir ejecuciones concurrentes

## 🔑 Variables Importantes

### Entorno Bootstrap (`envs/bootstrap/variables.tf`)

| Variable | Descripción | Default |
|----------|-------------|---------|
| `bucket_name` | Nombre del bucket S3 para el estado | `zend-terraform-state` |
| `dynamodb_table_name` | Nombre de la tabla DynamoDB para locks | `zend-terraform-locks` |
| `aws_region` | Región de AWS | `mx-central-1` |
| `project_name` | Nombre del proyecto para tagging | `zend-app` |

### Entorno Producción (`envs/prod/variables.tf`)

| Variable | Descripción | Default |
|----------|-------------|---------|
| `aws_region` | Región de AWS | `mx-central-1` |
| `short_region` | Código corto de región para naming | `mxc1` |
| `environment` | Nombre del entorno | `prod` |
| `project_name` | Nombre del proyecto | `zend-app` |

### Módulo Network (`modules/network/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `vpc_cidr` | CIDR block para la VPC | Sí |
| `public_subnet_cidr` | CIDR block para subred pública | Sí |
| `public_subnet_az` | Availability Zone para subred pública | Sí |
| `private_subnet_cidr` | CIDR block para subred privada | Sí |
| `private_subnet_az` | Availability Zone para subred privada | Sí |
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `tags` | Tags comunes para todos los recursos | No |

## 📝 Comandos Comunes

### Bootstrap

```bash
cd envs/bootstrap

# Inicializar
terraform init

# Ver plan
terraform plan

# Aplicar cambios
terraform apply

# Ver outputs
terraform output

# Destruir recursos (¡cuidado!)
terraform destroy
```

### Producción

```bash
cd envs/prod

# Inicializar con backend remoto
terraform init

# Si necesitas reconfigurar el backend
terraform init -reconfigure

# Ver plan
terraform plan

# Aplicar cambios
terraform apply

# Ver outputs
terraform output

# Ver estado
terraform show

# Destruir infraestructura (¡cuidado!)
terraform destroy
```

## ⚠️ Notas Importantes

1. **Orden de ejecución**: Siempre ejecuta `bootstrap` antes de `prod` la primera vez.

2. **Backend remoto**: Una vez configurado el backend remoto en `prod`, el estado se almacena en S3. No edites el estado manualmente.

3. **Bloqueo de estado**: DynamoDB previene ejecuciones concurrentes de Terraform. Si un proceso se interrumpe, el lock puede quedar activo. En ese caso, elimina manualmente el item en DynamoDB.

4. **Costo**: El bucket S3 y la tabla DynamoDB tienen costos mínimos (generalmente dentro del tier gratuito para proyectos pequeños).

5. **Seguridad**: El bucket S3 tiene acceso público bloqueado y encriptación habilitada por defecto.

## 🔄 Próximos Pasos

Mejoras recomendadas para el futuro:

- [ ] Agregar NAT Gateway para conectividad saliente de la subred privada
- [ ] Crear múltiples subredes por AZ para alta disponibilidad
- [ ] Agregar Security Groups y NACLs
- [ ] Implementar VPC Endpoints para servicios AWS
- [ ] Agregar validaciones en variables
- [ ] Crear módulos adicionales (compute, databases, etc.)

## 📚 Recursos

- [Documentación de Terraform](https://www.terraform.io/docs)
- [AWS Provider para Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Mejores Prácticas de Terraform](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Última actualización**: 2024

