# Skill: Add Terraform Module

## Objetivo

Agregar un nuevo módulo Terraform al proyecto `infra-aws-zend` siguiendo la estructura existente.

## Cuándo usar

Cuando se necesite crear infraestructura nueva que no encaja claramente en módulos existentes.

Ejemplos:

- CloudWatch monitoring
- Auto Scaling Group
- Redis/ElastiCache
- SQS
- SNS
- Lambda
- Backup Vault
- IAM separado

## Pasos

1. Crear carpeta:

```bash
mkdir -p modules/<module_name>
touch modules/<module_name>/main.tf
touch modules/<module_name>/variables.tf
touch modules/<module_name>/outputs.tf
```

2. Definir `variables.tf` con:
   - `name_prefix`
   - `tags`
   - variables específicas del módulo

3. Definir recursos en `main.tf`.

4. Definir outputs útiles en `outputs.tf`.

5. Consumir el módulo desde `envs/prod/main.tf`.

6. Agregar variables necesarias en `envs/prod/variables.tf`.

7. Agregar outputs en `envs/prod/outputs.tf` si aplica.

8. Validar:

```bash
terraform fmt -recursive
cd envs/prod
terraform validate
terraform plan
```

## Criterios de aceptación

- El módulo es independiente.
- No contiene valores hardcodeados innecesarios.
- Usa `tags`.
- Tiene variables tipadas.
- Tiene outputs relevantes.
- El plan no destruye recursos inesperadamente.
