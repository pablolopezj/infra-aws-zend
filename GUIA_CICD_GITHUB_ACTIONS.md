# Guía: CI/CD con GitHub Actions, S3 y AWS SSM

Esta guía explica cómo desplegar tu aplicación utilizando la estrategia de **Artefactos Inmutables**.
En lugar de usar `git pull` en el servidor, GitHub Actions empaqueta tu código en un `.zip`, lo sube a S3, y AWS SSM lo despliega en la instancia EC2.

## 🚀 Ventajas

- **Seguridad**: No necesitas llaves SSH ni Git tokens en el servidor.
- **Atomicidad**: Despliegas una versión exacta y completa del código.
- **Rollback**: Es fácil volver a una versión anterior (simplemente despliegas el zip previo).

---

## 1. Configurar Usuario en AWS (IAM)

El usuario `github-actions-deployer` necesita permisos para subir archivos a S3 y ejecutar comandos SSM.

**Política JSON Actualizada:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::zend-app-prod-mxc1-app-data",
                "arn:aws:s3:::zend-app-prod-mxc1-app-data/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand",
                "ssm:GetCommandInvocation"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## 2. Configurar Secretos en GitHub

En tu repositorio > **Settings** > **Secrets and variables** > **Actions**, agrega:

| Nombre | Valor (Ejemplo) | Cómo obtenerlo |
|--------|-----------------|----------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | IAM Console |
| `AWS_SECRET_ACCESS_KEY` | `wJal...` | IAM Console |
| `AWS_REGION` | `mx-central-1` | `mx-central-1` |
| `EC2_INSTANCE_ID` | `i-012...` | `terraform output ec2_instance_id` |
| `S3_BUCKET_NAME` | `zend-app-prod-mxc1-app-data` | `terraform output s3_bucket_id` |

---

## 3. Workflow (`.github/workflows/deploy.yml`)

Este flujo empaqueta el código, lo sube a S3 y le ordena a la EC2 que lo descargue e instale.

```yaml
name: Deploy to EC2 via S3 & SSM

on:
  push:
    branches: [ "main" ]

env:
  # Directorio donde vive la app en el servidor
  APP_DIR: "/var/www/zend-app"
  # Nombre del archivo para esta versión (usa el hash del commit)
  ARTIFACT_NAME: "app-${{ github.sha }}.zip"

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    # (Opcional) Build steps si es React/Angular/Vue
    # - name: Build
    #   run: |
    #     npm install
    #     npm run build

    - name: Interact with AWS
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Zip Artifact
      run: |
        # Excluir archivos innecesarios para ahorrar espacio y tiempo
        zip -r ${{ env.ARTIFACT_NAME }} . -x "*.git*" "node_modules/*" ".github/*"

    - name: Upload to S3
      run: |
        aws s3 cp ${{ env.ARTIFACT_NAME }} s3://${{ secrets.S3_BUCKET_NAME }}/deployments/${{ env.ARTIFACT_NAME }}

    - name: Deploy to EC2
      run: |
        echo "Desplegando versión ${{ github.sha }}..."
        
        # Script que se ejecutará en la EC2
        COMMANDS='[
            "echo \"Borrando artefactos viejos (opcional)...\"",
            "rm -f /tmp/app-deploy.zip",
            
            "echo \"Descargando artefacto de S3...\"",
            "aws s3 cp s3://${{ secrets.S3_BUCKET_NAME }}/deployments/${{ env.ARTIFACT_NAME }} /tmp/app-deploy.zip",
            
            "echo \"Creando directorio de app si no existe...\"",
            "mkdir -p ${{ env.APP_DIR }}",
            
            "echo \"Descomprimiendo...\"",
            "unzip -o /tmp/app-deploy.zip -d ${{ env.APP_DIR }}",
            
            "echo \"Instalando dependencias...\"",
            "cd ${{ env.APP_DIR }}",
            "if [ -f package.json ]; then npm install --production; fi",
            
            "echo \"Reiniciando servicio...\"",
            "pm2 restart all || pm2 start server.js --name app",
            
            "echo \"Limpieza...\"",
            "rm /tmp/app-deploy.zip"
        ]'

        # Envío del comando
        COMMAND_ID=$(aws ssm send-command \
          --document-name "AWS-RunShellScript" \
          --targets "Key=instanceids,Values=${{ secrets.EC2_INSTANCE_ID }}" \
          --comment "Deploy ${{ github.sha }}" \
          --parameters "commands=$COMMANDS" \
          --query "Command.CommandId" \
          --output text)
        
        echo "Command ID: $COMMAND_ID - Esperando ejecución..."
        
        aws ssm wait command-executed \
          --command-id "$COMMAND_ID" \
          --instance-id "${{ secrets.EC2_INSTANCE_ID }}"
        
        # Obtener salida (logs)
        aws ssm get-command-invocation \
          --command-id "$COMMAND_ID" \
          --instance-id "${{ secrets.EC2_INSTANCE_ID }}" \
          --query "StandardOutputContent" \
          --output text
```

## Requisitos en la Instancia EC2

Para que esto funcione, tu instancia necesita:

1. **Permiso S3**: Ya lo tiene (vía `ec2_s3_role` de Terraform).
2. **Unzip**: `sudo dnf install unzip -y` (si no está instalado).
3. **PM2/Node**: O el runtime que use tu app.

¡Listo! Ahora tienes un pipeline profesional y seguro.
