# Guía de Conexión Remota (Vía AWS SSM)

Esta guía detalla los pasos para conectar a la infraestructura (EC2 y RDS) utilizando **AWS Systems Manager (SSM)**. Este método es más seguro que SSH tradicional ya que no requiere abrir puertos (22) al internet público.

## 1. Prerrequisitos

### AWS CLI y Session Manager Plugin
Necesitas tener instaladas las siguientes herramientas en tu computadora local:

1.  **AWS CLI**: Configurado con tus credenciales.
    ```bash
    aws configure
    ```
2.  **Session Manager Plugin**: Complemento necesario para el CLI.
    - **MacOS (Homebrew)**: `brew install --cask session-manager-plugin`
    - **Otros**: [Guía de instalación oficial](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## 2. Obtener Datos de Conexión
Ejecuta el siguiente comando en el directorio `envs/prod` para obtener los IDs necesarios:

```bash
cd envs/prod
INSTANCIA_ID=$(terraform output -raw ec2_instance_id)
RDS_ADDRESS=$(terraform output -raw rds_address)

echo "Instancia ID: $INSTANCIA_ID"
echo "RDS Address:  $RDS_ADDRESS"
```

## 3. Conectarse a la Instancia (Shell Web)

Para obtener una terminal en la instancia privada:

```bash
aws ssm start-session --target $INSTANCIA_ID --region mx-central-1
```

*Nota: Entrarás como usuario `ssm-user` o `ec2-user` dependiendo de la configuración. Para cambiar a root: `sudo -i`.*

## 4. Conectarse a la Base de Datos (RDS)

Dado que la RDS está en una subred privada, usaremos la instancia EC2 como puente mediante un túnel (Port Forwarding) gestionado por SSM.

### Paso A: Abrir el túnel
Este comando redirige el puerto local `5433` hacia el puerto `5432` de la RDS remota.

```bash
aws ssm start-session \
    --target $INSTANCIA_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["'$RDS_ADDRESS'"],"portNumber":["5432"], "localPortNumber":["5433"]}' \
    --region mx-central-1
```

**Mantén esta terminal abierta.** Verás un mensaje como "Waiting for connections...".

### Paso B: Conectar tu Cliente SQL
Configura tu cliente favorito (DBeaver, pgAdmin, DataGrip):

- **Host**: `localhost` (o `127.0.0.1`)
- **Port**: `5433`
- **User**: `postgres` (o el usuario maestro configurado)
- **Password**: Recupérala de AWS Secrets Manager:
  ```bash
  aws secretsmanager get-secret-value \
      --secret-id $(terraform output -raw rds_secret_arn) \
      --query SecretString --output text \
      --region mx-central-1
  ```
- **Database**: `zenddb`

## Solución de Problemas Comunes

- **Error "SessionManagerPlugin is not found"**: Instala el plugin (ver paso 1).
- **Error "Target not connected"**: La instancia EC2 puede estar apagada o reiniciándose. Espera unos minutos.
- **Error "Connection refused" en el cliente SQL**: Asegúrate de que la terminal del túnel (Paso A) siga abierta y sin errores.
