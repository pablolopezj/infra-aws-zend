# Skill: Add HTTPS End-to-End

## Objetivo

Configurar HTTPS desde el usuario hasta CloudFront y desde CloudFront hasta ALB.

## Estado actual

El proyecto ya tiene:

- CloudFront con dominio personalizado.
- ACM para CloudFront en `us-east-1`.
- ALB con listener HTTP.
- Listener HTTPS condicional si hay certificado.

## Objetivo técnico

Agregar o validar:

1. Certificado ACM regional para ALB en `mx-central-1`.
2. Listener HTTPS en ALB puerto 443.
3. Listener HTTP puerto 80 redirigiendo a HTTPS.
4. CloudFront origin protocol policy usando HTTPS hacia ALB.
5. Security Groups permitiendo 443 desde CloudFront/Internet según diseño.
6. Health checks funcionando.

## Importante

CloudFront requiere certificado en `us-east-1`.

ALB requiere certificado en la misma región del ALB:

```txt
mx-central-1
```

Por eso normalmente necesitas dos certificados ACM:

- Uno en `us-east-1` para CloudFront.
- Uno en `mx-central-1` para ALB.

## Variables sugeridas en ALB

```hcl
variable "certificate_arn" {
  description = "ARN del certificado ACM regional para HTTPS en ALB."
  type        = string
  default     = ""
}

variable "enable_http_to_https_redirect" {
  description = "Redirige HTTP a HTTPS cuando existe certificado."
  type        = bool
  default     = true
}
```

## Cambios en CloudFront

Si el origen es ALB, configurar:

```hcl
origin_protocol_policy = "https-only"
```

o equivalente en el módulo.

## Riesgos

- Certificado ACM no validado.
- Mismatch entre dominio y certificado.
- Health check fallando si backend solo responde HTTP.
- Redirecciones infinitas si Nginx/app no maneja `X-Forwarded-Proto`.
- Downtime si se reemplaza listener incorrectamente.

## Validación

```bash
curl -I https://scorpionpys.mx
curl -I http://scorpionpys.mx
curl -I https://<cloudfront-domain>
```

Esperado:

- HTTP redirige a HTTPS.
- HTTPS responde 200, 301 o 302 según app.
- Certificado válido.
- No hay mixed content.
