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

Este proyecto gestiona la infraestructura completa para la aplicación Zend en AWS, incluyendo:

- **VPC** con subredes públicas y privadas
- **Internet Gateway** para conectividad pública
- **Tablas de ruteo** para subredes públicas y privadas
- **Security Groups y Network ACLs** para seguridad de red
- **VPC Endpoints** (S3 y DynamoDB) para minimizar tráfico externo
- **Instancias EC2** con configuración personalizada
- **Volúmenes EBS** con snapshots automáticos
- **Key Pairs** para acceso SSH seguro
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
    ├── network/            # Módulo de red (VPC, subredes, IGW, Security Groups, NACLs, VPC Endpoints)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/             # Módulo de compute (EC2, EBS, Snapshots automáticos)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── keypair/             # Módulo para Key Pairs SSH
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── state_backend/       # Módulo para backend de Terraform (S3 + DynamoDB)
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
   - Recursos de VPC (VPC, Subnets, Internet Gateway, Route Tables, Security Groups, NACLs)
   - Instancias EC2
   - Volúmenes EBS
   - Key Pairs
   - IAM Roles y Policies (para Data Lifecycle Manager)

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
   - Security Groups (público y privado)
   - Network ACLs (público y privado)
   - VPC Endpoints para S3 y DynamoDB
   - Instancia EC2 (t4g.medium) con Amazon Linux 2023
   - Volumen EBS (100 GB gp3) con snapshots automáticos (1 vez al día)
   - Key Pair para acceso SSH (si está configurado)

5. Verifica los outputs:
   ```bash
   terraform output
   ```

## 🏗️ Arquitectura

### Recursos de Red Creados

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC                                  │
│                    (10.0.0.0/16)                            │
│                                                              │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │   Subred Pública     │    │   Subred Privada     │      │
│  │   (10.0.1.0/24)      │    │   (10.0.2.0/24)      │      │
│  │   mx-central-1a      │    │   mx-central-1b       │      │
│  │                      │    │                      │      │
│  │  Security Group      │    │  Security Group      │      │
│  │  (Público)           │    │  (Privado)           │      │
│  │                      │    │                      │      │
│  │  Network ACL         │    │  Network ACL         │      │
│  │  (Público)           │    │  (Privado)           │      │
│  │                      │    │                      │      │
│  │  Route Table         │    │  Route Table         │      │
│  │  (Pública)           │    │  (Privada)           │      │
│  └──────────┬───────────┘    └──────────┬───────────┘      │
│             │                           │                  │
│             │                           │                  │
│             │    ┌──────────────┐       │                  │
│             │    │  EC2 Instance│       │                  │
│             │    │  (t4g.medium)│       │                  │
│             │    │  + EBS 100GB│       │                  │
│             │    └──────────────┘       │                  │
└─────────────┼───────────────────────────┼──────────────────┘
              │                           │
              │                           │
              ▼                           ▼
    ┌─────────────────┐         ┌──────────────────┐
    │ Internet        │         │ VPC Endpoints    │
    │ Gateway         │         │ (S3, DynamoDB)   │
    └─────────────────┘         └──────────────────┘
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
| `vpc_cidr` | CIDR block para la VPC | `10.0.0.0/16` |
| `public_subnet_cidr` | CIDR block para subred pública | `10.0.1.0/24` |
| `public_subnet_az` | Availability Zone para subred pública | `mx-central-1a` |
| `private_subnet_cidr` | CIDR block para subred privada | `10.0.2.0/24` |
| `private_subnet_az` | Availability Zone para subred privada | `mx-central-1b` |
| `enable_ec2_instance` | Habilitar creación de instancia EC2 | `true` |
| `ec2_instance_type` | Tipo de instancia EC2 | `t4g.medium` |
| `ec2_key_name` | Nombre del key pair para SSH | `zend-app-key` |
| `ec2_subnet_tier` | Subnet para EC2 (public/private) | `private` |
| `create_key_pair` | Crear key pair con Terraform | `false` |
| `public_key_path` | Ruta a la clave pública SSH | `""` |

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
| `enable_vpc_endpoints` | Habilitar VPC Endpoints (S3, DynamoDB) | No (default: `true`) |
| `allowed_public_ingress_cidrs` | CIDRs permitidos para acceso público | No (default: `["0.0.0.0/0"]`) |

### Módulo Compute (`modules/compute/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `subnet_id` | ID de la subred donde crear la instancia | Sí |
| `security_group_ids` | Lista de Security Group IDs | Sí |
| `instance_type` | Tipo de instancia EC2 | No (default: `t4g.medium`) |
| `key_name` | Nombre del key pair para SSH | No |
| `monitoring_enabled` | Habilitar monitoreo detallado | No (default: `false`) |
| `ebs_volume_size` | Tamaño del volumen EBS en GB | No (default: `100`) |
| `ebs_volume_type` | Tipo de volumen EBS | No (default: `gp3`) |
| `ebs_iops` | IOPS para volúmenes gp3 | No (default: `3000`) |
| `ebs_throughput` | Throughput en MB/s para gp3 | No (default: `125`) |
| `enable_snapshots` | Número de snapshots por día | No (default: `1`) |
| `snapshot_retention_days` | Días de retención de snapshots | No (default: `7`) |
| `tags` | Tags comunes para todos los recursos | No |

### Módulo Key Pair (`modules/keypair/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `key_name` | Nombre del key pair en AWS | Sí |
| `public_key` | Contenido de la clave pública SSH | Sí |
| `tags` | Tags para el key pair | No |

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

3. **Bloqueo de estado**: DynamoDB previene ejecuciones concurrentes de Terraform. Si un proceso se interrumpe, el lock puede quedar activo. Ver `SOLUCION_LOCK.md` para resolverlo.

4. **Key Pairs**: Para crear un key pair, consulta `CREAR_KEY_PAIR.md`. La clave privada nunca debe subirse a Git.

5. **Snapshots EBS**: Los snapshots se crean automáticamente (1 vez al día por defecto) y se retienen 7 días. Costo estimado: ~$0.75-1.50 USD/mes.

6. **Costo**: 
   - Backend (S3 + DynamoDB): ~$0-1 USD/mes
   - VPC y Networking: Gratis
   - EC2 (t4g.medium): ~$30-40 USD/mes (depende de Savings Plans)
   - EBS (100 GB gp3): ~$8 USD/mes
   - Snapshots: ~$0.75-1.50 USD/mes

7. **Seguridad**: 
   - El bucket S3 tiene acceso público bloqueado y encriptación habilitada
   - Security Groups y NACLs configurados por defecto
   - VPC Endpoints minimizan tráfico externo
   - Volúmenes EBS encriptados por defecto

## 🔄 Próximos Pasos

Mejoras recomendadas para el futuro:

- [x] Agregar Security Groups y NACLs ✅
- [x] Implementar VPC Endpoints para servicios AWS ✅
- [x] Agregar validaciones en variables ✅
- [x] Crear módulo de compute (EC2) ✅
- [x] Crear módulo de Key Pairs ✅
- [ ] Agregar NAT Gateway para conectividad saliente de la subred privada
- [ ] Crear múltiples subredes por AZ para alta disponibilidad
- [ ] Agregar módulo de bases de datos (RDS)
- [ ] Agregar módulo de Load Balancer (ALB)
- [ ] Implementar Auto Scaling Groups
- [ ] Agregar CloudWatch Alarms y Logs

## 📚 Documentación Adicional

- **[CREAR_KEY_PAIR.md](CREAR_KEY_PAIR.md)**: Guía para crear y configurar Key Pairs SSH
- **[VERIFICACION.md](VERIFICACION.md)**: Guía completa para verificar que todo se creó correctamente
- **[ACTUALIZACION.md](ACTUALIZACION.md)**: Guía para actualizar recursos de seguridad
- **[SOLUCION_LOCK.md](SOLUCION_LOCK.md)**: Solución de problemas con State Locks

## 📚 Recursos

- [Documentación de Terraform](https://www.terraform.io/docs)
- [AWS Provider para Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Mejores Prácticas de Terraform](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Última actualización**: 2024

