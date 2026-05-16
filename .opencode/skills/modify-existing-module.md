# Skill: Modify Existing Terraform Module

## Objetivo

Modificar un módulo existente sin romper compatibilidad con `envs/prod`.

## Pasos

1. Identificar módulo afectado.
2. Revisar:
   - `main.tf`
   - `variables.tf`
   - `outputs.tf`

3. Si agregas una variable:
   - declarar en el módulo,
   - pasar desde `envs/prod/main.tf`,
   - declarar en `envs/prod/variables.tf` si debe ser configurable.

4. Si agregas un output:
   - declarar en el módulo,
   - exponer en `envs/prod/outputs.tf` si el usuario lo necesita.

5. Ejecutar validación.

## Reglas

- No cambiar nombres de recursos existentes sin analizar impacto.
- No cambiar `count` o `for_each` sin revisar recreaciones.
- No cambiar nombres de recursos físicos AWS en producción sin plan de migración.
- Para cambios destructivos, explicar rollback.

## Validación

```bash
terraform fmt -recursive
cd envs/prod
terraform validate
terraform plan
```

## Salida esperada

```md
## Módulo modificado

## Archivos modificados

## Código

## Impacto esperado en Terraform plan

## Riesgos
```
