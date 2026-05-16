# Skill: Add Terraform Output

## Objetivo

Agregar outputs útiles sin exponer información sensible.

## Template normal

```hcl
output "resource_id" {
  description = "ID del recurso creado."
  value       = aws_resource.example.id
}
```

## Template sensible

```hcl
output "secret_arn" {
  description = "ARN del secreto en AWS Secrets Manager."
  value       = aws_secretsmanager_secret.example.arn
  sensitive   = true
}
```

## Reglas

- No exponer passwords.
- No exponer private keys.
- No exponer connection strings con credenciales.
- Marcar como `sensitive = true` si contiene:
  - secretos,
  - tokens,
  - passwords,
  - ARNs sensibles,
  - datos de conexión privados.
- Exponer outputs de módulos en `envs/prod/outputs.tf` solo si serán usados por personas, CI/CD o módulos externos.
