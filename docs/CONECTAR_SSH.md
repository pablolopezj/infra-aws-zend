# Guía: Conectarse a EC2 vía SSH

Esta guía te muestra cómo conectarte a tu instancia EC2 usando SSH.

## 📋 Prerrequisitos

1. **Key Pair configurado**: Debes tener el key pair creado y la clave privada en tu máquina local
2. **IP de la instancia**: Necesitas la IP pública o privada de la instancia
3. **Security Group**: El Security Group debe permitir tráfico SSH (puerto 22)

## 🔍 Paso 1: Verificar que tienes el Key Pair

### Opción A: Si creaste el key pair con Terraform

```bash
# Verificar que el key pair existe
aws ec2 describe-key-pairs --key-names zend-app-key --region mx-central-1

# Verificar que tienes la clave privada
ls -la ~/.ssh/zend-app-key
```

### Opción B: Si usaste AWS CLI

```bash
# Verificar que tienes el archivo .pem
ls -la ~/.ssh/zend-app-key.pem

# Verificar permisos (debe ser 400)
chmod 400 ~/.ssh/zend-app-key.pem
```

## 🔍 Paso 2: Obtener la IP de la Instancia

### Método 1: Usando Terraform Outputs

```bash
cd envs/prod

# Obtener IP pública
terraform output ec2_instance_public_ip

# Obtener IP privada
terraform output ec2_instance_private_ip

# Obtener ID de la instancia
terraform output ec2_instance_id
```

### Método 2: Usando AWS CLI

```bash
# Obtener IP pública
aws ec2 describe-instances \
  --instance-ids $(cd envs/prod && terraform output -raw ec2_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Obtener IP privada
aws ec2 describe-instances \
  --instance-ids $(cd envs/prod && terraform output -raw ec2_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text
```

## 🔐 Paso 3: Verificar Security Group

El Security Group debe permitir tráfico SSH desde tu IP. Si la instancia está en subnet privada, necesitarás un bastion host o VPN.

### Verificar reglas del Security Group

```bash
# Obtener ID del Security Group
SG_ID=$(cd envs/prod && terraform output -raw private_security_group_id)

# Ver reglas de entrada
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region mx-central-1 \
  --query 'SecurityGroups[0].IpPermissions'
```

### Agregar regla SSH si es necesario

Si necesitas agregar una regla SSH al Security Group, puedes hacerlo manualmente en la consola AWS o actualizar el módulo network.

## 🚀 Paso 4: Conectarse vía SSH

### Si la instancia está en Subnet Pública

```bash
# Obtener IP pública
PUBLIC_IP=$(cd envs/prod && terraform output -raw ec2_instance_public_ip)

# Conectarse (Amazon Linux 2023 usa 'ec2-user')
ssh -i ~/.ssh/zend-app-key ec2-user@$PUBLIC_IP

# O si usaste .pem
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$PUBLIC_IP
```

### Si la instancia está en Subnet Privada

Si la instancia está en subnet privada, **NO tendrá IP pública**. Necesitas:

1. **Opción 1: Usar un Bastion Host** (instancia en subnet pública)
2. **Opción 2: Usar VPN o Direct Connect**
3. **Opción 3: Usar AWS Systems Manager Session Manager** (sin SSH)

#### Con Bastion Host (SSH Tunnel)

```bash
# Paso 1: Conectarte al bastion
BASTION_IP="<IP_DEL_BASTION>"
ssh -i ~/.ssh/zend-app-key ec2-user@$BASTION_IP

# Paso 2: Desde el bastion, conectarte a la instancia privada
PRIVATE_IP=$(cd envs/prod && terraform output -raw ec2_instance_private_ip)
ssh -i ~/.ssh/zend-app-key ec2-user@$PRIVATE_IP
```

#### SSH Tunnel directo (sin entrar al bastion)

```bash
BASTION_IP="<IP_DEL_BASTION>"
PRIVATE_IP=$(cd envs/prod && terraform output -raw ec2_instance_private_ip)

# Crear tunnel y conectarse en un solo paso
ssh -i ~/.ssh/zend-app-key \
    -o ProxyCommand="ssh -i ~/.ssh/zend-app-key -W %h:%p ec2-user@$BASTION_IP" \
    ec2-user@$PRIVATE_IP
```

## 👤 Usuarios SSH según AMI

El usuario SSH depende del sistema operativo:

| AMI | Usuario |
|-----|---------|
| Amazon Linux 2023 | `ec2-user` |
| Amazon Linux 2 | `ec2-user` |
| Ubuntu | `ubuntu` |
| Debian | `admin` |
| RHEL | `ec2-user` |
| CentOS | `centos` |
| SUSE | `ec2-user` |

## 🔧 Configuración SSH Avanzada

### Crear alias en ~/.ssh/config

Agrega esto a `~/.ssh/config`:

```
Host zend-prod
    HostName <IP_PUBLICA_O_PRIVADA>
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Luego puedes conectarte simplemente:

```bash
ssh zend-prod
```

### Si usas Bastion Host

```
Host zend-bastion
    HostName <IP_BASTION>
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key

Host zend-prod
    HostName <IP_PRIVADA>
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key
    ProxyJump zend-bastion
```

## ⚠️ Solución de Problemas

### Error: "Permission denied (publickey)"

**Causa**: La clave privada no coincide con la clave pública en AWS.

**Solución**:
```bash
# Verificar que estás usando la clave correcta
ssh -v -i ~/.ssh/zend-app-key ec2-user@<IP>

# Verificar permisos de la clave
chmod 400 ~/.ssh/zend-app-key
```

### Error: "Connection timed out"

**Causa**: 
- Security Group no permite SSH desde tu IP
- Instancia en subnet privada sin acceso
- Instancia no está corriendo

**Solución**:
```bash
# Verificar estado de la instancia
aws ec2 describe-instances \
  --instance-ids $(cd envs/prod && terraform output -raw ec2_instance_id) \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].State.Name'

# Verificar Security Group
# (ver Paso 3 arriba)
```

### Error: "Host key verification failed"

**Solución**:
```bash
# Limpiar known_hosts
ssh-keygen -R <IP_DE_LA_INSTANCIA>

# O usar StrictHostKeyChecking=no
ssh -o StrictHostKeyChecking=no -i ~/.ssh/zend-app-key ec2-user@<IP>
```

### No puedo conectarme a instancia en subnet privada

**Opciones**:
1. Crear un Bastion Host en subnet pública
2. Configurar VPN
3. Usar AWS Systems Manager Session Manager (no requiere SSH)

## 📝 Ejemplo Completo

```bash
# 1. Navegar al directorio de producción
cd envs/prod

# 2. Obtener IP pública
PUBLIC_IP=$(terraform output -raw ec2_instance_public_ip)
echo "Conectando a: $PUBLIC_IP"

# 3. Verificar que la clave existe
if [ ! -f ~/.ssh/zend-app-key ]; then
    echo "Error: Clave privada no encontrada en ~/.ssh/zend-app-key"
    exit 1
fi

# 4. Configurar permisos
chmod 400 ~/.ssh/zend-app-key

# 5. Conectarse
ssh -i ~/.ssh/zend-app-key ec2-user@$PUBLIC_IP
```

## 🔒 Seguridad

1. **Nunca compartas tu clave privada**
2. **Usa permisos 400 en la clave privada**: `chmod 400 ~/.ssh/zend-app-key`
3. **Restringe Security Groups**: Solo permite SSH desde IPs específicas si es posible
4. **Considera usar bastion hosts** para instancias en subnets privadas
5. **Deshabilita acceso root directo** en la instancia

## 📚 Referencias

- [AWS: Conectarse a instancia Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)
- [SSH Config File](https://www.ssh.com/academy/ssh/config)

---

**Última actualización**: 2024

