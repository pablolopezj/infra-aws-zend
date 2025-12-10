# Guía de Conexión Remota (Desde otra computadora)

Esta guía detalla los pasos para conectar a la infraestructura (EC2 y RDS) desde una computadora diferente a la que usó Terraform.

## 1. Transferir la Llave Privada (.pem)
Necesitas el archivo `.pem` (ej. `zend-app-key.pem`) que se generó o usó durante el despliegue.
- **Origen**: Computadora donde ejecutaste Terraform.
- **Destino**: `~/.ssh/` en la nueva computadora.

⚠️ **IMPORTANTE**: La llave no debe compartirse por medios inseguros (email, chat público). Usa USB seguro, SFTP o gestor de contraseñas.

## 2. Configurar Permisos
En la nueva computadora, abre una terminal y ajusta los permisos de la llave para que sea de lectura exclusiva para tu usuario (requisito de SSH):

```bash
chmod 400 ~/.ssh/zend-app-key.pem
```

## 3. Configurar SSH (`~/.ssh/config`)
Edita o crea el archivo de configuración SSH para simplificar el acceso.

**Archivo**: `~/.ssh/config`

```ssh
# ========================================
# Bastion Host (Puerta de Enlace)
# ========================================
Host bastion-zend
    # Reemplaza con la IP Publica real del Bastion (ver outputs de terraform)
    HostName 78.12.227.2
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# ========================================
# Instancia Privada (Vía Bastion)
# ========================================
Host zend-app
    # IP Privada de la instancia (ver outputs)
    HostName 10.0.2.229
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    ProxyCommand ssh -W %h:%p bastion-zend
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# ========================================
# Túnel a RDS (Base de Datos)
# ========================================
Host zend-rds-tunnel
    # Usamos el bastion como puente
    HostName 78.12.227.2
    User ec2-user
    IdentityFile ~/.ssh/zend-app-key.pem
    # Crea el túnel: Puerto Local 5433 -> RDS Puerto 5432
    # Reemplaza con el endpoint real de RDS
    LocalForward 5433 zend-app-prod-mxc1-postgres.xxxxxx.mx-central-1.rds.amazonaws.com:5432
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## 4. Conectarse

### A la Instancia Privada (EC2)
```bash
ssh zend-app
```

### A la Base de Datos (RDS)
1. **Abrir el túnel**:
   ```bash
   ssh -N zend-rds-tunnel
   ```
   *(Dejar esta terminal abierta, verás que "se cuelga", es normal, está esperando tráfico)*.

2. **Conectar Cliente SQL** (DBeaver, pgAdmin, Datagrip):
   - **Host**: `localhost` (o `127.0.0.1`)
   - **Port**: `5433`
   - **User**: `postgres`
   - **Password**: *(Obtenla de AWS Secrets Manager)*
   - **Database**: `zenddb`
