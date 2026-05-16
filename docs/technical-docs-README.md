# Documentación Técnica de Infraestructura - infra-aws-zend

> **Generado**: 2026-05-16 | **Basado en**: Análisis del código Terraform (sin `terraform plan` ni `terraform state`)

## Propósito

Esta carpeta contiene la documentación técnica completa del estado actual de la infraestructura AWS para la aplicación `scorpionpys.mx`, generada a partir del análisis exhaustivo del código Terraform.

**Importante**: Esta documentación refleja lo que está definido en el código. Puede haber diferencias con el estado real en AWS. Valida siempre con `terraform plan` antes de tomar decisiones operativas.

## Cómo usar esta documentación

1. **Inicio**: Lee `architecture-overview.md` para entender la arquitectura general.
2. **Módulos**: Consulta `module-inventory.md` para detalles de cada módulo Terraform.
3. **Recursos AWS**: Revisa `resource-inventory.md` para un inventario completo por servicio.
4. **Despliegue**: Sigue `deployment-flow.md` para entender el flujo bootstrap → prod.
5. **Red**: Consulta `networking.md` para detalles de VPC, subnets, routing y flujo de tráfico.
6. **Seguridad**: Revisa `security-review.md` para hallazgos clasificados por severidad.
7. **Costos**: Consulta `cost-review.md` para estimaciones y optimizaciones.
8. **Operaciones**: Usa `operational-runbook.md` y `terraform-commands.md` para el día a día.
9. **Riesgos**: Revisa `known-risks.md` para riesgos conocidos.
10. **Próximos pasos**: Consulta `recommended-next-steps.md` para mejoras priorizadas.

## Convenciones

| Marca | Significado |
|-------|-------------|
| **Confirmado por código** | Recurso existe en el código Terraform verificado |
| **Inferido** | Deducido del código o configuración, no directamente visible |
| **Pendiente de validar con `terraform plan`** | No verificado contra el estado planificado |
| **Pendiente de validar en AWS** | No verificado contra la consola AWS real |
| **Documentado pero no verificado en código** | Aparece en docs/README pero no tiene recurso Terraform |

## Inconsistencias conocidas

| Hallazgo | Detalle |
|----------|---------|
| Route 53 | Documentado en README como "configurado" pero no existe módulo ni recurso Terraform |
| ACM (Certificate Manager) | Certificado referenciado por ARN hardcodeado en tfvars, no gestionado por Terraform |
| `private_subnet_az` | Default en variables.tf dice `mx-central-1b`, tfvars override a `mx-central-1a` |
| `enable_alb` | ALB solo se crea cuando `enable_alb && enable_cloudfront` son ambos true |
| Contraseña RDS en tfvars | Hardcodeada en texto plano; pero se usa `random_password` en producción |

## Índice de documentos

| Documento | Descripción |
|-----------|-------------|
| [architecture-overview.md](architecture-overview.md) | Arquitectura general con diagrama Mermaid |
| [module-inventory.md](module-inventory.md) | Inventario de módulos Terraform |
| [resource-inventory.md](resource-inventory.md) | Inventario de recursos AWS por servicio |
| [deployment-flow.md](deployment-flow.md) | Flujo de despliegue bootstrap → prod |
| [networking.md](networking.md) | Documentación de red (VPC, subnets, routing) |
| [security-review.md](security-review.md) | Revisión de seguridad con hallazgos clasificados |
| [cost-review.md](cost-review.md) | Análisis de costos y optimizaciones |
| [operational-runbook.md](operational-runbook.md) | Runbook de operaciones frecuentes |
| [terraform-commands.md](terraform-commands.md) | Comandos seguros de Terraform |
| [known-risks.md](known-risks.md) | Riesgos conocidos actuales |
| [recommended-next-steps.md](recommended-next-steps.md) | Próximos pasos priorizados |

## Resumen rápido de la infraestructura

| Aspecto | Valor |
|---------|-------|
| **Región principal** | mx-central-1 |
| **Región secundaria** | us-east-1 (WAF, ACM) |
| **VPC CIDR** | 10.0.0.0/16 |
| **Subnets** | 4 (2 públicas, 2 privadas) en 3 AZs |
| **EC2** | t4g.medium, Amazon Linux 2023 ARM64 |
| **RDS** | PostgreSQL 16.11, db.t4g.medium, 200GB gp3 |
| **CloudFront** | Con ACM, dominio scorpionpys.mx |
| **WAF** | AWSManagedRulesCommonRuleSet + KnownBadInputs |
| **Backend TF** | S3 + DynamoDB en mx-central-1 |