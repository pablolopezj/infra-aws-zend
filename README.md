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

- **VPC** con subredes públicas y privadas (múltiples AZs para ALB)
- **Internet Gateway** para conectividad pública
- **Tablas de ruteo** para subredes públicas y privadas
- **Security Groups y Network ACLs** para seguridad de red
- **VPC Endpoints** (S3 y DynamoDB) para minimizar tráfico externo
- **Bastion Host** para acceso seguro a instancias privadas
- **Instancias EC2** con configuración personalizada (volúmenes de 30GB)
- **Volúmenes EBS** con snapshots automáticos
- **Key Pairs** para acceso SSH seguro
- **S3 Bucket** para almacenamiento de la aplicación con lifecycle policies y OAI para CloudFront
- **ALB (Application Load Balancer)** con soporte para HTTP/HTTPS condicional
- **CloudFront** con soporte para orígenes S3 y ALB/EC2, y OAI para acceso seguro a S3
- **WAF (Web Application Firewall)** asociado a CloudFront para protección contra ataques
- **RDS PostgreSQL** (opcional, comentado por defecto)
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
    ├── bastion/             # Módulo para Bastion Host
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/                  # Módulo para S3 Bucket de aplicación
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── alb/                 # Módulo para Application Load Balancer
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloudfront/          # Módulo para CloudFront Distribution
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── waf/                 # Módulo para Web Application Firewall
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    ├── rds/                 # Módulo para RDS PostgreSQL (opcional)
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
   - Segunda subred pública en `mx-central-1b` con CIDR `10.0.3.0/24` (para ALB)
   - Subred privada en `mx-central-1b` con CIDR `10.0.2.0/24`
   - Internet Gateway
   - Tablas de ruteo para subredes públicas y privadas
   - Security Groups (público y privado)
   - Network ACLs (público y privado)
   - VPC Endpoints para S3 y DynamoDB
   - Instancia EC2 (t4g.medium) con Amazon Linux 2023 en subnet privada
   - Volumen root EBS (30 GB gp3) y volumen de datos (100 GB gp3) con snapshots automáticos
   - Bastion Host (t4g.micro) con volumen root de 30 GB en subnet pública
   - S3 Bucket para almacenamiento de la aplicación con lifecycle policies y OAI para CloudFront
   - IAM Role y Policy para acceso a S3 desde EC2
   - ALB (Application Load Balancer) en subredes públicas (2 AZs) con listeners HTTP/HTTPS condicionales
   - CloudFront Distribution con soporte para orígenes S3 (con OAI) o ALB/EC2
   - WAF (Web Application Firewall) en us-east-1 asociado a CloudFront
   - Key Pair para acceso SSH (si está configurado)
   - RDS PostgreSQL (opcional, comentado por defecto)

5. Verifica los outputs:
   ```bash
   terraform output
   ```

## 🏗️ Arquitectura

### Arquitectura de Red y Aplicación

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet                                    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    CloudFront + WAF                          │  │
│  │              (Global CDN + Web Application Firewall)         │  │
│  └───────────────────────────┬──────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Application Load Balancer                 │  │
│  │                    (HTTP/HTTPS condicional)                  │  │
│  └───────────────────────────┬──────────────────────────────────┘  │
│                              │                                       │
└──────────────────────────────┼───────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         VPC                                        │
│                    (10.0.0.0/16)                                  │
│                                                                    │
│  ┌──────────────────────┐  ┌──────────────────────┐              │
│  │   Subred Pública A   │  │   Subred Pública B   │              │
│  │   (10.0.1.0/24)      │  │   (10.0.3.0/24)      │              │
│  │   mx-central-1a      │  │   mx-central-1b      │              │
│  │                      │  │                      │              │
│  │  ┌──────────────┐    │  │                      │              │
│  │  │ Bastion Host │    │  │                      │              │
│  │  │ (t4g.micro)  │    │  │                      │              │
│  │  │ 30GB root    │    │  │                      │              │
│  │  └──────────────┘    │  │                      │              │
│  │                      │  │                      │              │
│  │  ┌──────────────┐    │  │  ┌──────────────┐    │              │
│  │  │     ALB      │    │  │  │     ALB      │    │              │
│  │  │  (Subnet A)  │    │  │  │  (Subnet B)  │    │              │
│  │  └──────────────┘    │  │  └──────────────┘    │              │
│  └──────────────────────┘  └──────────────────────┘              │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Subred Privada                            │  │
│  │                    (10.0.2.0/24)                             │  │
│  │                    mx-central-1b                             │  │
│  │                                                              │  │
│  │  ┌──────────────┐                                           │  │
│  │  │ EC2 Instance │                                           │  │
│  │  │ (t4g.medium) │                                           │  │
│  │  │ 30GB root    │                                           │  │
│  │  │ + EBS 100GB  │                                           │  │
│  │  └──────────────┘                                           │  │
│  │                                                              │  │
│  │  ┌──────────────┐                                           │  │
│  │  │ S3 Bucket    │  ← CloudFront OAI (acceso seguro)        │  │
│  │  │ (app-data)   │                                           │  │
│  │  └──────────────┘                                           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    VPC Endpoints                              │  │
│  │                    (S3, DynamoDB)                            │  │
│  └──────────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
                    ┌───────────────────┐
                    │ Internet Gateway  │
                    └───────────────────┘
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
| `enable_bastion` | Habilitar creación de bastion host | `true` |
| `bastion_instance_type` | Tipo de instancia para bastion | `t4g.micro` |
| `bastion_allowed_ssh_cidrs` | CIDRs permitidos para SSH al bastion | `["0.0.0.0/0"]` |
| `enable_s3` | Habilitar creación de bucket S3 | `true` |
| `s3_bucket_name` | Nombre del bucket S3 (vacío = auto-generado) | `""` |
| `s3_enable_versioning` | Habilitar versionado en S3 | `false` |
| `s3_enable_lifecycle_transition` | Habilitar transiciones a Glacier | `true` |
| `s3_transition_to_glacier_ir_days` | Días antes de transición a Glacier IR | `30` |
| `s3_noncurrent_version_expiration_days` | Días antes de expirar versiones antiguas | `90` |
| `create_ec2_s3_role` | Crear IAM role para EC2 acceder a S3 | `true` |

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

### Módulo Bastion (`modules/bastion/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `vpc_id` | ID de la VPC | Sí |
| `subnet_id` | ID de la subnet pública | Sí |
| `vpc_cidr` | CIDR block de la VPC | Sí |
| `instance_type` | Tipo de instancia para bastion | No (default: `t4g.micro`) |
| `key_name` | Nombre del key pair para SSH | Sí |
| `allowed_ssh_cidrs` | CIDRs permitidos para SSH | No (default: `["0.0.0.0/0"]`) |
| `tags` | Tags comunes para todos los recursos | No |

### Módulo S3 (`modules/s3/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `bucket_name` | Nombre del bucket S3 | Sí |
| `enable_versioning` | Habilitar versionado | No (default: `false`) |
| `enable_lifecycle_transition` | Habilitar transiciones a Glacier | No (default: `true`) |
| `transition_to_glacier_ir_days` | Días antes de transición a Glacier IR | No (default: `30`) |
| `transition_to_glacier_days` | Días antes de transición a Glacier (0=deshabilitado) | No (default: `0`) |
| `transition_to_deep_archive_days` | Días antes de transición a Deep Archive (0=deshabilitado) | No (default: `0`) |
| `noncurrent_version_transition_to_glacier_ir_days` | Días antes de transicionar versiones no actuales a Glacier IR | No (default: `7`) |
| `noncurrent_version_expiration_days` | Días antes de expirar versiones antiguas (0=deshabilitado) | No (default: `90`) |
| `allowed_principal_arns` | ARNs de IAM permitidos para acceder al bucket | No (default: `[]`) |
| `cloudfront_oai_iam_arn` | ARN IAM del OAI de CloudFront para acceso seguro | No (default: `""`) |
| `tags` | Tags comunes para todos los recursos | No |

### Módulo ALB (`modules/alb/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `vpc_id` | ID de la VPC | Sí |
| `subnet_ids` | Lista de IDs de subredes (mínimo 2 en diferentes AZs) | Sí |
| `target_instance_ids` | Lista de IDs de instancias EC2 | No (default: `[]`) |
| `target_port` | Puerto del target | No (default: `80`) |
| `target_protocol` | Protocolo del target (HTTP/HTTPS) | No (default: `HTTP`) |
| `certificate_arn` | ARN del certificado ACM para HTTPS (vacío = solo HTTP) | No (default: `""`) |
| `enable_deletion_protection` | Habilitar protección contra eliminación | No (default: `false`) |
| `tags` | Tags comunes para todos los recursos | No |

**Nota**: El listener HTTP redirige a HTTPS solo si hay certificado; de lo contrario, hace forward directo al target group.

### Módulo CloudFront (`modules/cloudfront/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `origin_domain_name` | Dominio del origen (ALB, EC2, o S3) | Sí |
| `origin_type` | Tipo de origen: `s3` o `custom` | No (default: `custom`) |
| `origin_id` | ID del origen | Sí |
| `waf_web_acl_id` | ARN del WAF Web ACL (requiere ARN completo, no ID) | No (default: `""`) |
| `price_class` | Clase de precio de CloudFront | No (default: `PriceClass_100`) |
| `viewer_protocol_policy` | Política de protocolo del viewer | No (default: `redirect-to-https`) |
| `use_default_certificate` | Usar certificado por defecto de CloudFront | No (default: `true`) |
| `tags` | Tags comunes para todos los recursos | No |

**Nota**: CloudFront puede usar orígenes S3 (con OAI para acceso seguro) o ALB/EC2. El WAF debe estar en `us-east-1` y requiere el ARN completo.

### Módulo WAF (`modules/waf/variables.tf`)

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `name_prefix` | Prefijo para nombres de recursos | Sí |
| `enable_rate_limiting` | Habilitar rate limiting | No (default: `false`) |
| `rate_limit` | Límite de requests por 5 minutos | No (default: `2000`) |
| `tags` | Tags comunes para todos los recursos | No |

**Nota**: El WAF para CloudFront DEBE crearse en `us-east-1` (configurado automáticamente con provider alias).

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

# Ver IPs de recursos
terraform output bastion_public_ip
terraform output ec2_instance_private_ip

# Ver información de S3
terraform output s3_bucket_id
terraform output s3_bucket_arn
terraform output ec2_s3_role_arn

# Ver información de ALB
terraform output alb_dns_name
terraform output alb_target_group_arn

# Ver información de CloudFront
terraform output cloudfront_distribution_id
terraform output cloudfront_distribution_domain_name
terraform output cloudfront_distribution_arn

# Ver información de WAF
terraform output waf_web_acl_id
terraform output waf_web_acl_arn

# Destruir infraestructura (¡cuidado!)
terraform destroy
```

### Conectarse a las Instancias

#### Conectarse al Bastion

```bash
cd envs/prod

# Obtener IP del bastion
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Conectarse
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$BASTION_IP
```

#### Conectarse a la Instancia Privada (a través del Bastion)

**Opción 1: Usando configuración SSH (recomendado)**

Primero, actualiza tu configuración SSH:

```bash
# Ejecutar script de actualización
./actualizar_ssh_config.sh

# O manualmente, agrega a ~/.ssh/config:
# Host bastion-zend
#     HostName <BASTION_IP>
#     User ec2-user
#     IdentityFile ~/.ssh/zend-app-key.pem
#     StrictHostKeyChecking no
#
# Host zend-app
#     HostName <PRIVATE_IP>
#     User ec2-user
#     IdentityFile ~/.ssh/zend-app-key.pem
#     ProxyCommand ssh -W %h:%p bastion-zend
#     StrictHostKeyChecking no
```

Luego conectarte simplemente:

```bash
ssh zend-app
```

**Opción 2: Comando directo**

```bash
cd envs/prod
BASTION_IP=$(terraform output -raw bastion_public_ip)
PRIVATE_IP=$(terraform output -raw ec2_instance_private_ip)

ssh -i ~/.ssh/zend-app-key.pem \
    -o ProxyCommand="ssh -i ~/.ssh/zend-app-key.pem -W %h:%p ec2-user@$BASTION_IP" \
    ec2-user@$PRIVATE_IP
```

**Opción 3: En dos pasos**

```bash
# 1. Conectarse al bastion
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$BASTION_IP

# 2. Desde el bastion, conectarse a la instancia privada
ssh ec2-user@$PRIVATE_IP
```

#### Acceder a S3 desde la Instancia EC2

La instancia EC2 tiene acceso automático al bucket S3 a través de un IAM Role:

```bash
# Conectarse a la instancia
ssh zend-app

# Obtener nombre del bucket (desde tu máquina local)
cd envs/prod
BUCKET_NAME=$(terraform output -raw s3_bucket_id)
echo "Bucket: $BUCKET_NAME"

# Desde la instancia EC2, listar objetos
aws s3 ls s3://$BUCKET_NAME

# Subir un archivo
aws s3 cp archivo.txt s3://$BUCKET_NAME/

# Descargar un archivo
aws s3 cp s3://$BUCKET_NAME/archivo.txt ./

# Sincronizar directorio
aws s3 sync ./mi-directorio s3://$BUCKET_NAME/mi-directorio/

# Ver información del bucket
aws s3api get-bucket-location --bucket $BUCKET_NAME
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET_NAME
```

**Nota**: El bucket S3 se crea con el nombre: `zend-app-prod-mxc1-app-data` (o el especificado en `s3_bucket_name`).

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
   - Bastion (t4g.micro): ~$7-10 USD/mes
   - EBS (30GB root + 100GB data gp3): ~$10.40 USD/mes
   - Snapshots: ~$0.75-1.50 USD/mes
   - S3 Standard (200 GB): ~$4.60 USD/mes
   - S3 Glacier IR (800 GB): ~$4.00 USD/mes
   - S3 Requests y transiciones: ~$0.25 USD/mes
   - ALB (si habilitado): ~$16-22 USD/mes + LCU
   - CloudFront (50 GB salida, 1M requests): ~$4.50 USD/mes
   - WAF (1 Web ACL, 3 reglas, 1 managed rule group): ~$5-10 USD/mes
   - **Total estimado (sin ALB/CloudFront/WAF)**: ~$57-72 USD/mes
   - **Total estimado (con ALB/CloudFront/WAF)**: ~$82-106 USD/mes

7. **Seguridad**: 
   - El bucket S3 tiene acceso público bloqueado y encriptación habilitada
   - Security Groups y NACLs configurados por defecto
   - Network ACL público permite SSH (puerto 22) para acceso al bastion
   - Security Group privado permite SSH desde subnet pública (bastion access)
   - VPC Endpoints minimizan tráfico externo
   - Volúmenes EBS encriptados por defecto (30GB root para Bastion y EC2)
   - Instancias privadas solo accesibles a través del bastion host
   - S3 bucket con encriptación AES256 y acceso restringido a IAM roles y CloudFront OAI
   - IAM Role y Policy creados automáticamente para acceso desde EC2
   - CloudFront con OAI (Origin Access Identity) para acceso seguro a S3
   - WAF con reglas administradas de AWS (Common Rule Set, Known Bad Inputs)
   - ALB con listeners HTTP/HTTPS condicionales (solo redirige a HTTPS si hay certificado)
   - **Recomendación**: Restringir `bastion_allowed_ssh_cidrs` a tu IP específica en producción

## 🔄 Próximos Pasos

Mejoras recomendadas para el futuro:

- [x] Agregar Security Groups y NACLs ✅
- [x] Implementar VPC Endpoints para servicios AWS ✅
- [x] Agregar validaciones en variables ✅
- [x] Crear módulo de compute (EC2) ✅
- [x] Crear módulo de Key Pairs ✅
- [x] Crear Bastion Host para acceso seguro ✅
- [x] Crear módulo S3 para almacenamiento de aplicación ✅
- [x] Implementar lifecycle policies para optimización de costos ✅
- [x] Crear módulo de Load Balancer (ALB) ✅
- [x] Crear módulo de CloudFront con soporte S3 y OAI ✅
- [x] Crear módulo de WAF asociado a CloudFront ✅
- [x] Implementar segunda subnet pública para ALB (2 AZs) ✅
- [x] Configurar acceso seguro S3 con CloudFront OAI ✅
- [ ] Agregar NAT Gateway para conectividad saliente de la subred privada
- [ ] Crear múltiples subredes privadas por AZ para alta disponibilidad
- [ ] Agregar módulo de bases de datos (RDS) - código listo, descomentar para usar
- [ ] Implementar Auto Scaling Groups
- [ ] Agregar CloudWatch Alarms y Logs
- [ ] Configurar certificados ACM para HTTPS en ALB

## 📚 Documentación Adicional

- **[CREAR_KEY_PAIR.md](CREAR_KEY_PAIR.md)**: Guía para crear y configurar Key Pairs SSH
- **[VERIFICACION.md](VERIFICACION.md)**: Guía completa para verificar que todo se creó correctamente
- **[ACTUALIZACION.md](ACTUALIZACION.md)**: Guía para actualizar recursos de seguridad
- **[SOLUCION_LOCK.md](SOLUCION_LOCK.md)**: Solución de problemas con State Locks
- **[USO_BASTION.md](USO_BASTION.md)**: Guía completa para usar el Bastion Host
- **[TROUBLESHOOTING_SSH.md](TROUBLESHOOTING_SSH.md)**: Solución de problemas de conexión SSH

## 🛠️ Scripts Útiles

El proyecto incluye varios scripts para facilitar el trabajo:

- **`actualizar_ssh_config.sh`**: Actualiza automáticamente `~/.ssh/config` con las IPs actuales
- **`limpiar_ssh_config.sh`**: Limpia y actualiza la configuración SSH eliminando duplicados
- **`diagnostico_bastion.sh`**: Diagnostica problemas de conexión al bastion
- **`CONFIG_SSH_CORRECTO.txt`**: Plantilla de configuración SSH correcta

## 📚 Recursos

- [Documentación de Terraform](https://www.terraform.io/docs)
- [AWS Provider para Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Mejores Prácticas de Terraform](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Última actualización**: 2025-11-22

