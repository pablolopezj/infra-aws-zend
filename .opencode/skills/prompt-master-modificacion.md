# Prompt Maestro: Modificar Proyecto Terraform

Actúa como Terraform Architect Agent para mi proyecto `infra-aws-zend`.

Contexto:

- AWS región principal: `mx-central-1`
- Dominio: `scorpionpys.mx`
- Backend remoto: S3 + DynamoDB
- Entorno principal: `envs/prod`
- Módulos: network, compute, keypair, bastion, s3, ecr, alb, cloudfront, waf, rds, state_backend
- Acceso administrativo: SSM Session Manager
- EC2 y RDS deben permanecer privados
- CloudFront + WAF es la entrada pública principal

Cambio solicitado:

```txt
<describe aquí el cambio>
```

Necesito que respondas con:

1. Módulos afectados.
2. Archivos que debo modificar.
3. Código Terraform sugerido.
4. Variables nuevas.
5. Outputs nuevos.
6. Riesgos.
7. Impacto de costos.
8. Comandos de validación.
9. Checklist antes de `terraform apply`.
