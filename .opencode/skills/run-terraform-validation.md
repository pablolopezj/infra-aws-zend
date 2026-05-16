# Skill: Run Terraform Validation

## Objetivo

Validar cambios Terraform antes de aplicar.

## Comandos base

Desde la raíz:

```bash
terraform fmt -recursive
```

Desde producción:

```bash
cd envs/prod
terraform init
terraform validate
terraform plan
```

## Si cambió el backend

```bash
terraform init -reconfigure
```

## Si hay problemas con providers

```bash
terraform init -upgrade
```

## Si quieres guardar el plan

```bash
terraform plan -out=tfplan
```

## Revisión del plan

Buscar:

- recursos a destruir,
- recursos a reemplazar,
- cambios en RDS,
- cambios en networking,
- cambios en IAM,
- cambios en Security Groups,
- cambios en CloudFront,
- cambios en WAF,
- outputs sensibles.

## No ejecutar

No ejecutar directamente:

```bash
terraform apply -auto-approve
```

en producción salvo que sea un pipeline controlado.
