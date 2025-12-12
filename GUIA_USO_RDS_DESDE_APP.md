# Guía: Conectar Aplicación en EC2 a RDS PostgreSQL

Esta guía explica cómo configurar tu aplicación backend (Node.js, Python, PHP, Java, etc.) que corre dentro de la instancia EC2 para conectarse de forma segura a la base de datos RDS.

## 1. Arquitectura de Seguridad (Ya Configurada)

Tu infraestructura ya tiene listos los accesos necesarios:

1. **Red (Security Groups)**: El Security Group de la RDS (`sg-rds`) ya permite tráfico en el puerto `5432` proveniente del Security Group de la EC2 (`sg-private`). **No necesitas configurar firewalls adicionales.**
2. **Identidad (IAM Role)**: Tu instancia EC2 tiene un Rol de IAM asignado que le permite leer secretos de **AWS Secrets Manager**. No necesitas configurar `AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY` en la instancia; el SDK de AWS las detecta automáticamente.

## 2. Estrategias de Conexión

La mejor práctica es **NO escribir las contraseñas en archivos de configuración (`.env`, `config.js`)**. En su lugar, recupéralas dinámicamente al iniciar la aplicación.

### Opción A: Inyectar variables de entorno al arrancar (Recomendado para Docker/Systemd)

Puedes usar un script de arranque (entrypoint) que lea el secreto y exporte las variables antes de iniciar tu app.

**Ejemplo de script de arranque (`start.sh`):**

```bash
#!/bin/bash

# 1. Definir la Región y el ID del Secreto (puedes ver el ARN en los outputs de Terraform)
REGION="mx-central-1"
SECRET_ID=$(aws secretsmanager list-secrets --filter Key="name",Values="*rds-credentials*" --query "SecretList[0].Name" --output text --region $REGION)

echo "Recuperando credenciales de: $SECRET_ID"

# 2. Obtener el JSON completo del secreto
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --region "$REGION" --query SecretString --output text)

# 3. Parsear (usando jq, instalado por defecto en Amazon Linux 2023) y exportar
export DB_HOST=$(echo $SECRET_JSON | jq -r .host)
export DB_PORT=$(echo $SECRET_JSON | jq -r .port)
export DB_USER=$(echo $SECRET_JSON | jq -r .username)
export DB_PASSWORD=$(echo $SECRET_JSON | jq -r .password)
export DB_NAME=$(echo $SECRET_JSON | jq -r .dbname)

# 4. Iniciar tu aplicación
echo "Iniciando aplicación..."
# npm start / python main.py / java -jar app.jar
npm start
```

### Opción B: Leer Secrets Manager desde el Código (AWS SDK)

Tu aplicación puede pedir la contraseña directamente.

**Ejemplo en Node.js:**

```javascript
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const client = new SecretsManagerClient({ region: "mx-central-1" });

async function getDbConfig() {
  const command = new GetSecretValueCommand({ SecretId: "zend-app-prod-mxc1-rds-credentials" });
  const response = await client.send(command);
  const secret = JSON.parse(response.SecretString);
  
  return {
    host: secret.host,
    user: secret.username,
    password: secret.password,
    database: secret.dbname,
    port: secret.port
  };
}

// Usar config para conectar
getDbConfig().then(config => {
  const { Pool } = require('pg');
  const pool = new Pool(config);
  // ...
});
```

## 3. Verificación Manual

Si quieres probar la conexión manualmente desde la terminal de la EC2 (conectado vía SSM):

1. Instala el cliente de PostgreSQL:

   ```bash
   sudo dnf install postgresql15 -y
   ```

2. Obtén la contraseña y host:

   ```bash
   # Obtener nombre del secreto
   aws secretsmanager list-secrets --region mx-central-1

   # Obtener valores
   aws secretsmanager get-secret-value --secret-id <NOMBRE_DEL_SECRETO> --region mx-central-1
   ```

3. Conecta:

   ```bash
   psql -h <RDS_ENDPOINT> -U <USUARIO> -d <DB_NAME>
   ```
