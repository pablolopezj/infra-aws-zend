# Migración DNS a Route 53 - scorpionpys.mx

## ✅ Paso 1: Zona Hospedada Creada

He creado la zona hospedada en Route 53:

- **Hosted Zone ID:** `Z08086802F6G2PHVBYOD5`
- **Dominio:** `scorpionpys.mx`

---

## 📝 Paso 2: Actualizar Nameservers en Akky

Ve al panel de Akky y reemplaza los DNS actuales por estos **4 nameservers de AWS**:

```
ns-799.awsdns-35.net
ns-205.awsdns-25.com
ns-2034.awsdns-62.co.uk
ns-1075.awsdns-06.org
```

**Instrucciones:**

1. En la pantalla que mostraste, borra los DNS actuales
2. Pega estos 4 nameservers (uno en cada campo DNS 1, DNS 2, DNS 3, DNS 4)
3. Click en **GUARDAR**

⏱️ **Propagación:** 24-48 horas (aunque suele ser 2-6 horas)

---

## 🔍 Paso 3: Verificar Propagación

Después de actualizar en Akky, verifica que los cambios se hayan propagado:

```bash
# Desde tu terminal
nslookup -type=NS scorpionpys.mx
```

**Resultado esperado (cuando esté propagado):**

```
scorpionpys.mx  nameserver = ns-799.awsdns-35.net
scorpionpys.mx  nameserver = ns-205.awsdns-25.com
scorpionpys.mx  nameserver = ns-2034.awsdns-62.co.uk
scorpionpys.mx  nameserver = ns-1075.awsdns-06.org
```

---

## 📋 Paso 4: Agregar Registro CNAME de Validación ACM

Una vez que la propagación esté completa (o incluso antes, puedes agregarlo ya):

### 4.1 Obtener datos de validación de ACM

1. Ve a **AWS Certificate Manager** (región `us-east-1`)
2. Click en tu certificado pendiente
3. Copia el **CNAME name** y **CNAME value**

### 4.2 Agregar en Route 53

**Opción A - Consola AWS:**

1. Ve a **Route 53** → **Hosted zones** → `scorpionpys.mx`
2. Click **Create record**
3. Configuración:
   - **Record name:** Pega el CNAME name de ACM (ejemplo: `_abc123.scorpionpys.mx`)
   - **Record type:** CNAME
   - **Value:** Pega el CNAME value de ACM (ejemplo: `_xyz789.acm-validations.aws.`)
   - **TTL:** 300
4. Click **Create records**

**Opción B - AWS CLI:**

```bash
# Reemplaza con tus valores reales de ACM
aws route53 change-resource-record-sets \
  --hosted-zone-id Z08086802F6G2PHVBYOD5 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "_TU_CNAME_NAME.scorpionpys.mx",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "_TU_CNAME_VALUE.acm-validations.aws."}]
      }
    }]
  }'
```

---

## 🌐 Paso 5: Agregar Registro para CloudFront

Después de que el certificado esté validado, agrega el CNAME para tu app:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id Z08086802F6G2PHVBYOD5 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.scorpionpys.mx",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "dhbh04rnde8ns.cloudfront.net"}]
      }
    }]
  }'
```

Para el dominio raíz (`scorpionpys.mx`), usa un registro ALIAS:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id Z08086802F6G2PHVBYOD5 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "scorpionpys.mx",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "dhbh04rnde8ns.cloudfront.net",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

**Nota:** `Z2FDTNDATAQYW2` es el Hosted Zone ID fijo de CloudFront (no cambies este valor).

---

## 💰 Costos

- **Zona hospedada:** $0.50 USD/mes
- **Consultas DNS:** $0.40 USD por millón de consultas (primeras 1B consultas/mes)
- **Total estimado:** ~$0.50-1.00 USD/mes

---

## ✅ Checklist

- [ ] Actualizar nameservers en Akky
- [ ] Verificar propagación DNS (`nslookup -type=NS scorpionpys.mx`)
- [ ] Agregar registro CNAME de validación ACM en Route 53
- [ ] Esperar validación del certificado (5-30 min después de propagación)
- [ ] Configurar CloudFront con el certificado
- [ ] Agregar registros DNS para `www.scorpionpys.mx` y `scorpionpys.mx`
