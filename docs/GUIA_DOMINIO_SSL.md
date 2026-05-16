# Guía: Configurar Dominio Personalizado con SSL

Esta guía te ayudará a configurar tu dominio de Akky para que apunte a tu aplicación con HTTPS habilitado.

## 📋 Requisitos Previos

- Dominio registrado en Akky (ejemplo: `tudominio.com`)
- Acceso al panel DNS de Akky
- Acceso a la consola de AWS

---

## Paso 1: Solicitar Certificado SSL en AWS Certificate Manager (ACM)

### 1.1 Ir a ACM

1. Abre la consola de AWS
2. **Región:** Cambia a `us-east-1` (N. Virginia) - **IMPORTANTE para CloudFront**
3. Busca el servicio **Certificate Manager**
4. Click en **Request certificate**

### 1.2 Configurar el Certificado

1. Selecciona **Request a public certificate**
2. **Domain names:**
   - Agrega: `tudominio.com`
   - Agrega: `*.tudominio.com` (wildcard para subdominios)
   - Click **Next**
3. **Validation method:** Selecciona **DNS validation**
4. **Key algorithm:** RSA 2048 (default)
5. Click **Request**

### 1.3 Validar el Dominio

AWS te mostrará registros DNS que debes agregar:

**Ejemplo de registro:**

```
Nombre: _abc123def456.tudominio.com
Tipo: CNAME
Valor: _xyz789.acm-validations.aws.
```

**En el panel DNS de Akky:**

1. Ve a la sección de registros DNS
2. Crea un nuevo registro **CNAME**
3. Copia exactamente el **Nombre** y **Valor** que AWS te proporcionó
4. Guarda los cambios

⏱️ **Tiempo de validación:** 5-30 minutos. AWS verificará automáticamente.

---

## Paso 2: Configurar CloudFront con el Certificado

### Opción A: Vía Consola AWS (Manual)

1. Ve a **CloudFront** en la consola
2. Selecciona tu distribución: `dhbh04rnde8ns.cloudfront.net`
3. Click en **Edit**
4. En **Alternate domain names (CNAMEs):**
   - Agrega: `tudominio.com`
   - Agrega: `www.tudominio.com`
5. En **Custom SSL certificate:**
   - Selecciona el certificado que creaste en ACM
6. Click **Save changes**

### Opción B: Vía Terraform (Recomendado)

Actualiza tu archivo `envs/prod/variables.tf`:

```hcl
variable "custom_domain_name" {
  type        = string
  description = "Dominio personalizado"
  default     = "tudominio.com"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN del certificado ACM (us-east-1)"
  default     = ""  # Pega aquí el ARN del certificado
}
```

Luego actualiza `envs/prod/main.tf` en el módulo CloudFront:

```hcl
module "cloudfront" {
  # ... configuración existente ...
  
  # Agregar estas líneas:
  aliases                 = var.custom_domain_name != "" ? [var.custom_domain_name, "www.${var.custom_domain_name}"] : []
  acm_certificate_arn     = var.acm_certificate_arn
  use_default_certificate = var.acm_certificate_arn == "" ? true : false
}
```

Ejecuta:

```bash
terraform apply
```

---

## Paso 3: Configurar DNS en Akky

Una vez que CloudFront esté configurado con tu dominio:

### Para `www.tudominio.com`

**Registro CNAME:**

- **Nombre:** `www`
- **Tipo:** CNAME
- **Valor:** `dhbh04rnde8ns.cloudfront.net`
- **TTL:** 3600

### Para `tudominio.com` (dominio raíz)

**Opción 1 - Si Akky soporta ALIAS/ANAME:**

- **Nombre:** `@` o dejar vacío
- **Tipo:** ALIAS o ANAME
- **Valor:** `dhbh04rnde8ns.cloudfront.net`

**Opción 2 - Si NO soporta ALIAS:**
Tendrás que usar redirección:

- Configura `www.tudominio.com` con CNAME (como arriba)
- Configura una redirección HTTP 301 de `tudominio.com` → `www.tudominio.com`

**Opción 3 - Migrar DNS a Route 53 (AWS):**

- Más control y soporte nativo para ALIAS en dominios raíz
- Costo: ~$0.50/mes por zona hospedada

---

## Paso 4: Verificar

1. Espera 5-15 minutos para propagación DNS
2. Prueba en tu navegador:
   - `https://www.tudominio.com` ✅
   - `https://tudominio.com` ✅ (si configuraste ALIAS o redirección)

3. Verifica el certificado:
   - Click en el candado 🔒 en la barra de direcciones
   - Debe decir "Conexión segura"

---

## Solución de Problemas

### Error: "Certificate doesn't match domain"

- Verifica que agregaste el dominio en **Alternate domain names** de CloudFront
- Asegúrate de que el certificado esté en `us-east-1`

### DNS no resuelve

- Usa `nslookup www.tudominio.com` para verificar
- Espera hasta 48h para propagación completa (usualmente es mucho más rápido)

### CloudFront devuelve 403

- Verifica que el origen (ALB) esté respondiendo correctamente
- Revisa los logs de CloudFront en la consola

---

## Próximos Pasos Opcionales

1. **Forzar HTTPS:** Configura redirección HTTP → HTTPS en CloudFront (ya está por defecto)
2. **HSTS:** Agrega header `Strict-Transport-Security` en tu app
3. **Renovación automática:** ACM renueva automáticamente los certificados antes de expirar
