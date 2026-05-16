# Guía: Usar Bastion Host para Acceder a Instancias Privadas

## 🎯 ¿Qué es un Bastion Host?

Un bastion host es una instancia EC2 pequeña en la subnet pública que actúa como "puerta de entrada" segura para acceder a instancias en subnets privadas.

## 📋 Configuración Actual

- **Bastion**: `t4g.micro` en subnet pública
- **Instancia de aplicación**: `t4g.medium` en subnet privada
- **Costo del bastion**: ~$7-10 USD/mes

## 🔐 Paso 1: Conectarse al Bastion

### Obtener IP del Bastion

```bash
cd envs/prod

# Ver IP pública del bastion
terraform output bastion_public_ip

# O guardar en variable
BASTION_IP=$(terraform output -raw bastion_public_ip)
echo "Bastion IP: $BASTION_IP"
```

### Conectarse vía SSH

**Importante**: Usa el nombre correcto de tu archivo de clave (`.pem` o sin extensión):

```bash
# Si tu archivo se llama zend-app-key.pem
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$BASTION_IP

# Si tu archivo se llama zend-app-key (sin .pem)
ssh -i ~/.ssh/zend-app-key ec2-user@$BASTION_IP

# O directamente
ssh -i ~/.ssh/zend-app-key.pem ec2-user@$(terraform output -raw bastion_public_ip)
```

## 🚀 Paso 2: Desde el Bastion, Conectarse a Instancia Privada

### Obtener IP Privada de la Instancia

```bash
# Desde tu máquina local
PRIVATE_IP=$(cd envs/prod && terraform output -raw ec2_instance_private_ip)
echo "Private IP: $PRIVATE_IP"
```

### Conectarse desde el Bastion

```bash
# 1. Primero conectarte al bastion
ssh -i ~/.ssh/zend-app-key ec2-user@$BASTION_IP

# 2. Desde el bastion, conectarte a la instancia privada
ssh ec2-user@$PRIVATE_IP
# Nota: La clave privada se copia automáticamente o puedes usar el mismo key pair
```

## 🔧 Método Avanzado: SSH Tunnel (Un Solo Paso)

### Opción 1: ProxyJump (SSH 7.3+)

```bash
# Conectarse directamente a la instancia privada a través del bastion
BASTION_IP=$(cd envs/prod && terraform output -raw bastion_public_ip)
PRIVATE_IP=$(cd envs/prod && terraform output -raw ec2_instance_private_ip)

ssh -i ~/.ssh/zend-app-key \
    -o ProxyJump=ec2-user@$BASTION_IP \
    ec2-user@$PRIVATE_IP
```

### Opción 2: ProxyCommand (Compatible con versiones antiguas)

```bash
ssh -i ~/.ssh/zend-app-key \
    -o ProxyCommand="ssh -i ~/.ssh/zend-app-key -W %h:%p ec2-user@$BASTION_IP" \
    ec2-user@$PRIVATE_IP
```

## 📝 Configuración SSH Simplificada

Agrega esto a `~/.ssh/config`:

```
# Bastion Host
Host bastion-zend
    HostName <BASTION_IP>
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key
    StrictHostKeyChecking no

# Instancia Privada (a través del bastion)
Host zend-app
    HostName <PRIVATE_IP>
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key
    ProxyJump bastion-zend
    StrictHostKeyChecking no
```

Luego puedes conectarte simplemente:

```bash
# Al bastion
ssh bastion-zend

# A la instancia privada (automáticamente usa el bastion)
ssh zend-app
```

## 🔄 Port Forwarding a través del Bastion

### Forwarding de Puerto Local

```bash
# Forward puerto 8080 de la instancia privada a tu localhost:8080
BASTION_IP=$(cd envs/prod && terraform output -raw bastion_public_ip)
PRIVATE_IP=$(cd envs/prod && terraform output -raw ec2_instance_private_ip)

ssh -i ~/.ssh/zend-app-key \
    -L 8080:$PRIVATE_IP:8080 \
    -o ProxyJump=ec2-user@$BASTION_IP \
    ec2-user@$PRIVATE_IP -N
```

Luego accede a `http://localhost:8080` en tu navegador.

## 🔒 Seguridad

### Restringir Acceso al Bastion

Por defecto, el bastion permite SSH desde cualquier IP (`0.0.0.0/0`). Para mayor seguridad:

```bash
# Obtener tu IP pública
MY_IP=$(curl -s ifconfig.me)

# Aplicar con tu IP específica
cd envs/prod
terraform apply -var="bastion_allowed_ssh_cidrs=[\"$MY_IP/32\"]"
```

O edita `envs/prod/variables.tf`:

```terraform
variable "bastion_allowed_ssh_cidrs" {
  default = ["TU_IP/32"]  # Ejemplo: ["1.2.3.4/32"]
}
```

### Hardening del Bastion

El bastion ya incluye:
- ✅ Actualizaciones automáticas del sistema
- ✅ Herramientas básicas (htop, nano, git)
- ✅ Logs de inicialización
- ✅ Root volume encriptado

## 📊 Verificación

### Verificar que el Bastion está Corriendo

```bash
# Desde AWS CLI
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=zend-app-prod-mxc1-bastion" \
  --region mx-central-1 \
  --query 'Reservations[0].Instances[0].{State:State.Name,PublicIP:PublicIpAddress}'
```

### Verificar Conectividad

```bash
# Desde el bastion, probar conexión a instancia privada
ssh ec2-user@<PRIVATE_IP> "echo 'Conexión exitosa'"
```

## 💰 Costo

- **Bastion (t4g.micro)**: ~$7-10 USD/mes
- **Con Savings Plans**: ~$5-7 USD/mes
- **Sin uso**: Puedes detenerlo cuando no lo uses (solo pagas almacenamiento)

## 🛠️ Mantenimiento

### Detener el Bastion (Ahorrar Costos)

```bash
# Detener instancia
aws ec2 stop-instances \
  --instance-ids $(cd envs/prod && terraform output -raw bastion_instance_id) \
  --region mx-central-1
```

### Iniciar el Bastion

```bash
# Iniciar instancia
aws ec2 start-instances \
  --instance-ids $(cd envs/prod && terraform output -raw bastion_instance_id) \
  --region mx-central-1
```

### Actualizar el Bastion

```bash
# Conectarse al bastion
ssh bastion-zend

# Actualizar sistema
sudo yum update -y

# Reiniciar si es necesario
sudo reboot
```

## 🚨 Solución de Problemas

### Error: "Connection timed out" al Bastion

**Causa**: Security Group no permite tu IP

**Solución**:
```bash
# Verificar reglas del Security Group
aws ec2 describe-security-groups \
  --group-ids $(cd envs/prod && terraform output -raw bastion_security_group_id) \
  --region mx-central-1
```

### Error: "Permission denied" desde Bastion a Instancia Privada

**Causa**: Security Group privado no permite acceso desde bastion

**Solución**: Ya está configurado, pero verifica:
```bash
# El Security Group privado debe permitir SSH desde la subnet pública
```

### El Bastion no puede acceder a Instancia Privada

**Verificar**:
1. Security Group privado permite SSH desde subnet pública
2. La instancia privada está corriendo
3. El key pair está configurado en ambas instancias

## 📚 Comandos Útiles

```bash
# Ver todas las IPs
cd envs/prod
echo "Bastion: $(terraform output -raw bastion_public_ip)"
echo "App Private: $(terraform output -raw ec2_instance_private_ip)"

# Conectarse en un solo comando
ssh -i ~/.ssh/zend-app-key \
    -o ProxyJump=ec2-user@$(terraform output -raw bastion_public_ip) \
    ec2-user@$(terraform output -raw ec2_instance_private_ip)

# Copiar archivo a instancia privada a través del bastion
scp -i ~/.ssh/zend-app-key \
    -o ProxyJump=ec2-user@$(terraform output -raw bastion_public_ip) \
    archivo.txt ec2-user@$(terraform output -raw ec2_instance_private_ip):~/
```

---

**Última actualización**: 2024

