# Skill: Add Auto Scaling Group

## Objetivo

Migrar o extender la capa EC2 actual hacia Auto Scaling Group usando Launch Template.

## Contexto

Actualmente el proyecto usa una instancia EC2 `t4g.medium` en subnet privada.

La mejora recomendada es crear:

- Launch Template
- Auto Scaling Group
- Target Group attachment con ALB
- IAM Instance Profile
- User data
- Health checks
- Scaling policies opcionales

## Diseño recomendado

Crear nuevo módulo:

```txt
modules/asg/
├── main.tf
├── variables.tf
└── outputs.tf
```

## Variables sugeridas

```hcl
variable "name_prefix" {
  description = "Prefijo para nombres de recursos."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets privadas donde se desplegará el ASG."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups para las instancias del ASG."
  type        = list(string)
}

variable "target_group_arns" {
  description = "Target Groups del ALB asociados al ASG."
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t4g.medium"
}

variable "min_size" {
  description = "Capacidad mínima del ASG."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Capacidad máxima del ASG."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Capacidad deseada del ASG."
  type        = number
  default     = 1
}

variable "iam_instance_profile_name" {
  description = "Nombre del IAM Instance Profile para EC2."
  type        = string
}

variable "user_data" {
  description = "User data para inicializar la instancia."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
```

## Consideraciones

- No eliminar EC2 actual hasta validar ASG.
- Evitar downtime usando estrategia progresiva.
- Registrar instancias ASG en el Target Group del ALB.
- Usar health check tipo `ELB`.
- Evaluar almacenamiento persistente: si la app depende de EBS local, ASG requiere rediseño.

## Validación

```bash
terraform fmt -recursive
cd envs/prod
terraform validate
terraform plan
```

## Riesgos

- Reemplazo accidental de instancia actual.
- Pérdida de datos si la app usa disco local.
- Fallos de health check si Nginx/app no responde en el puerto correcto.
- Incremento de costos por múltiples instancias.
