# Skill: Add CloudWatch Monitoring

## Objetivo

Agregar monitoreo con CloudWatch Logs y CloudWatch Alarms.

## Recursos candidatos

- EC2 CPU
- EC2 Status Check
- ALB 5XX
- ALB Target Response Time
- RDS CPU
- RDS Free Storage
- RDS Connections
- NAT Gateway bytes
- CloudFront 5XX
- WAF blocked requests
- EBS Burst Balance si aplica

## Diseño recomendado

Crear módulo:

```txt
modules/monitoring/
├── main.tf
├── variables.tf
└── outputs.tf
```

## Alarmas mínimas recomendadas

### EC2

- CPU > 80%
- StatusCheckFailed > 0

### ALB

- HTTPCode_ELB_5XX_Count > 5
- HTTPCode_Target_5XX_Count > 5
- TargetResponseTime > 2s

### RDS

- CPUUtilization > 80%
- FreeStorageSpace bajo
- DatabaseConnections alto

### CloudFront

- 5xxErrorRate alto

## Variables sugeridas

```hcl
variable "name_prefix" {
  description = "Prefijo para nombres."
  type        = string
}

variable "alarm_actions" {
  description = "Lista de ARNs SNS para notificaciones."
  type        = list(string)
  default     = []
}

variable "ec2_instance_id" {
  description = "ID de la instancia EC2."
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ARN suffix del ALB para métricas CloudWatch."
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "ARN suffix del Target Group."
  type        = string
  default     = ""
}

variable "rds_instance_id" {
  description = "ID de instancia RDS."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
```

## Buenas prácticas

- Crear SNS topic para alertas.
- Definir thresholds moderados al inicio.
- Configurar retención de logs para controlar costos.
- No dejar logs con retención infinita salvo necesidad legal.

## Validación

```bash
terraform fmt -recursive
cd envs/prod
terraform validate
terraform plan
```
