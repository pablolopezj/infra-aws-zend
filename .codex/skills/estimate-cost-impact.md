# Skill: Estimate Cost Impact

## Objetivo

Analizar el impacto de costos antes de agregar o modificar recursos AWS.

## Recursos de costo alto en este proyecto

- NAT Gateway
- ALB
- WAF
- RDS
- EC2 siempre encendida
- EBS sobredimensionado
- Snapshots frecuentes
- CloudFront con mucho tráfico
- Logs con retención indefinida

## Checklist

Para cada cambio:

1. ¿Agrega costo fijo mensual?
2. ¿Agrega costo por tráfico?
3. ¿Agrega costo por almacenamiento?
4. ¿Agrega costo por requests?
5. ¿Puede apagarse en ambientes no productivos?
6. ¿Existe alternativa serverless o managed más barata?
7. ¿Puede usarse VPC Endpoint en lugar de NAT Gateway?
8. ¿Se puede limitar retención de logs?

## Salida

```md
## Recurso

## Tipo de costo

## Estimación cualitativa

## Riesgo

## Alternativa más barata

## Recomendación
```
