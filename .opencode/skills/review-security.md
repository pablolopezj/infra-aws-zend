# Skill: Review Security

## Objetivo

Revisar cambios Terraform desde el punto de vista de seguridad.

## Checklist

### Network

- RDS no debe ser pública.
- EC2 productiva debe estar en subnet privada.
- Bastion debe estar deshabilitado si SSM es suficiente.
- SSH no debe estar abierto a `0.0.0.0/0`.
- PostgreSQL no debe estar abierto a internet.
- ALB solo debe exponer HTTP/HTTPS.

### IAM

- Evitar `Action = "*"` salvo casos justificados.
- Evitar `Resource = "*"` salvo servicios que lo requieren.
- EC2 debe tener solo permisos necesarios.
- CI/CD debe usar OIDC si es posible.

### S3

- Public access block habilitado.
- Encryption habilitada.
- Bucket policy restrictiva.
- CloudFront OAI/OAC para acceso privado.

### Secrets

- No poner passwords en:
  - variables normales,
  - outputs,
  - user_data,
  - GitHub Actions logs,
  - archivos `.tfvars` versionados.

### TLS

- CloudFront debe usar HTTPS.
- ACM para CloudFront debe estar en `us-east-1`.
- ALB debe usar HTTPS si se implementa end-to-end TLS.

## Salida

```md
## Hallazgo

## Severidad

## Evidencia

## Corrección sugerida
```
