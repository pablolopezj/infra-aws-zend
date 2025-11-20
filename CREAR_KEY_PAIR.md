# Guía: Crear Key Pair para SSH en AWS

Esta guía te muestra cómo crear un key pair para acceder a tu instancia EC2 vía SSH.

## 🔑 Opción 1: Crear Key Pair con AWS CLI (Rápido)

### Paso 1: Crear el Key Pair

```bash
aws ec2 create-key-pair \
  --key-name zend-app-key \
  --region mx-central-1 \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/zend-app-key.pem
```

### Paso 2: Configurar permisos

```bash
chmod 400 ~/.ssh/zend-app-key.pem
```

### Paso 3: Actualizar la variable en Terraform

Edita `envs/prod/variables.tf` o pasa el valor al aplicar:

```bash
cd envs/prod
terraform apply -var="ec2_key_name=zend-app-key"
```

O actualiza el default en `envs/prod/variables.tf`:
```terraform
variable "ec2_key_name" {
  default = "zend-app-key"
}
```

### Paso 4: Conectarse vía SSH

```bash
ssh -i ~/.ssh/zend-app-key.pem ec2-user@<IP_PUBLICA>
```

---

## 🏗️ Opción 2: Crear Key Pair con Terraform (Recomendado)

Esta opción es mejor porque mantiene todo como código y permite versionar la clave pública.

### Paso 1: Generar el Key Pair localmente

```bash
# Generar clave privada
ssh-keygen -t rsa -b 4096 -f ~/.ssh/zend-app-key -N ""

# Esto crea:
# - ~/.ssh/zend-app-key (clave privada)
# - ~/.ssh/zend-app-key.pub (clave pública)
```

### Paso 2: Crear módulo de Key Pair en Terraform

Ya te creo el módulo...

### Paso 3: Usar el Key Pair en EC2

El módulo automáticamente usará el key pair creado.

---

## 📝 Notas Importantes

### Seguridad

1. **Nunca subas la clave privada (.pem) a Git**
   - Agrega `*.pem` y `*.key` a `.gitignore`
   - Guarda la clave privada en un lugar seguro

2. **Permisos correctos**
   ```bash
   chmod 400 ~/.ssh/zend-app-key.pem
   ```

3. **Usuario SSH según AMI**
   - Amazon Linux 2023: `ec2-user`
   - Ubuntu: `ubuntu`
   - Debian: `admin`
   - RHEL: `ec2-user`

### Ubicación de la clave

- **Clave privada**: Guarda en `~/.ssh/` con permisos 400
- **Clave pública**: Se sube a AWS automáticamente

---

## 🔄 Si ya tienes un Key Pair

Si ya tienes un key pair en AWS, solo necesitas:

1. Ver tus key pairs:
   ```bash
   aws ec2 describe-key-pairs --region mx-central-1
   ```

2. Usar el nombre en Terraform:
   ```bash
   terraform apply -var="ec2_key_name=tu-key-existente"
   ```

---

## ✅ Verificación

Después de crear el key pair y aplicar Terraform:

```bash
# Verificar que el key pair está asociado a la instancia
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw ec2_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].KeyName'
```

---

**Última actualización**: 2024

