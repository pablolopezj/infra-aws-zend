# AI Operating Guide - infra-aws-zend

Este directorio contiene agentes y skills para modificar de forma segura la infraestructura Terraform del proyecto `infra-aws-zend`.

## Agentes

| Agente | Uso |
|---|---|
| terraform-architect | Diseño general de cambios Terraform |
| network-agent | VPC, subnets, NAT, SG, NACL, endpoints |
| compute-agent | EC2, EBS, SSM, ASG, Launch Templates |
| security-agent | IAM, WAF, Secrets, TLS, hardening |
| database-agent | RDS PostgreSQL, Secrets Manager, backups |
| cicd-agent | GitHub Actions, ECR, deploy vía SSM |
| cost-optimizer-agent | Costos AWS y optimización |
| reviewer-agent | Revisión final antes de apply |

## Skills

| Skill | Uso |
|---|---|
| add-terraform-module | Crear módulo nuevo |
| modify-existing-module | Cambiar módulo existente |
| add-variable | Agregar variable correctamente |
| add-output | Agregar output seguro |
| run-terraform-validation | Validar cambios |
| review-security | Revisar seguridad |
| estimate-cost-impact | Analizar costos |
| add-cloudwatch-monitoring | Agregar logs y alarmas |
| add-autoscaling-group | Agregar ASG |
| add-https-end-to-end | Configurar HTTPS completo |

## Flujo recomendado para cualquier cambio

1. Usar `terraform-architect` para diseñar.
2. Usar agente especializado según el área:
   - red,
   - compute,
   - seguridad,
   - base de datos,
   - CI/CD,
   - costos.
3. Aplicar una skill concreta.
4. Usar `reviewer-agent`.
5. Ejecutar:

```bash
terraform fmt -recursive
cd envs/prod
terraform validate
terraform plan
```

6. Revisar el plan manualmente.
7. Aplicar solo si el plan es seguro.

## Reglas globales

- No ejecutar `terraform apply` sin revisar plan.
- No exponer secretos.
- No abrir SSH o RDS públicamente.
- No modificar backend remoto sin justificación.
- No cambiar nombres físicos de recursos productivos sin evaluar recreación.
- Todo cambio debe considerar seguridad, costo y rollback.
