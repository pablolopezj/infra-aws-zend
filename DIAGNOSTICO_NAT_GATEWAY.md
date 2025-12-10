# Diagnóstico de Problema con NAT Gateway

## Estado Actual

- ✅ **NAT Gateway**: Disponible (nat-08467670a4ceb5d0f)
- ✅ **Ruta**: Configurada correctamente (0.0.0.0/0 → NAT Gateway)
- ✅ **Security Group Privado**: Permite tráfico saliente y entrante desde cualquier lugar
- ✅ **Security Group Bastion**: Permite tráfico entrante desde VPC
- ✅ **Network ACL Privado**: Permite tráfico saliente a 0.0.0.0/0
- ✅ **Network ACL Público**: Permite tráfico entrante desde 10.0.0.0/16
- ✅ **Conectividad VPC**: Funciona (bastion responde a ping)

## Problema

El tráfico desde la instancia privada no puede llegar a Internet a través del NAT Gateway:
- ❌ Ping a 8.8.8.8: Timeout
- ❌ HTTP a 8.8.8.8: Timeout
- ❌ HTTPS a Google: Timeout
- ✅ Ping a bastion (10.0.1.232): Funciona
- ✅ Ping a gateway local (10.0.2.1): Funciona

## Posibles Causas

1. **Tráfico no está saliendo de la instancia**
   - Verificar con tcpdump si los paquetes salen de la interfaz de red
   - Comando: `sudo tcpdump -i ens5 -n -c 10 'host 8.8.8.8'`

2. **Tráfico bloqueado en Network ACL**
   - Aunque las reglas parecen correctas, podría haber un problema con el orden
   - Verificar si hay reglas DENY que bloqueen antes de las reglas ALLOW

3. **Tráfico no llega al NAT Gateway**
   - El NAT Gateway está en la subnet pública
   - El tráfico debe pasar por el Network ACL público
   - Verificar si el tráfico está siendo bloqueado en el Network ACL público

4. **Tráfico de retorno bloqueado**
   - El Security Group privado permite tráfico entrante desde 0.0.0.0/0
   - Verificar si hay algún problema con el tráfico de retorno

5. **Problema con el NAT Gateway mismo**
   - El NAT Gateway está en estado "available"
   - Pero podría haber un problema con su procesamiento de tráfico

## Próximos Pasos

1. **Verificar si el tráfico está saliendo de la instancia**
   ```bash
   sudo yum install -y tcpdump
   sudo tcpdump -i ens5 -n -c 10 'host 8.8.8.8' &
   curl -v --connect-timeout 5 http://8.8.8.8
   sudo pkill tcpdump
   ```

2. **Habilitar VPC Flow Logs**
   - Crear rol IAM para VPC Flow Logs
   - Habilitar Flow Logs en la VPC
   - Revisar logs para ver dónde se bloquea el tráfico

3. **Verificar conectividad con NAT Gateway**
   ```bash
   ping -c 3 10.0.1.241  # IP privada del NAT Gateway
   ```

4. **Revisar Network ACLs más detalladamente**
   - Verificar si hay reglas DENY que bloqueen el tráfico
   - Verificar el orden de las reglas

## Configuración Actual

### NAT Gateway
- **ID**: nat-08467670a4ceb5d0f
- **Estado**: available
- **Subnet**: subnet-0aaf69df01e1abe24 (pública)
- **IP Privada**: 10.0.1.241
- **IP Pública**: 78.13.234.90

### Instancia Privada
- **ID**: i-008a75b46791ada08
- **IP Privada**: 10.0.2.229
- **Subnet**: subnet-01ec7433f2ac3cde7 (privada, mx-central-1a)
- **Security Group**: sg-01d92d2c453e9a582
- **Network ACL**: acl-01c50be5297014fe3

### Rutas
- **Tabla de ruteo privada**: rtb-0cf6a87975bec9720
- **Ruta 0.0.0.0/0**: → nat-08467670a4ceb5d0f (activa)

