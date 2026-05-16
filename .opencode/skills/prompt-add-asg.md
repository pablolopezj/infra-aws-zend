# Prompt: Implementar Auto Scaling Group

Actúa como Compute Agent y usa la skill `add-autoscaling-group`.

Quiero agregar Auto Scaling Group al proyecto `infra-aws-zend`.

Condiciones:

- Mantener EC2 en subnets privadas.
- Usar Launch Template.
- Registrar instancias en el Target Group actual del ALB.
- Usar SSM para administración.
- No eliminar todavía la EC2 actual.
- Mantener instancia `t4g.medium`.
- desired_capacity = 1
- min_size = 1
- max_size = 2

Genera:

1. Nuevo módulo `modules/asg`.
2. Variables.
3. Outputs.
4. Ejemplo de integración en `envs/prod/main.tf`.
5. Variables necesarias en `envs/prod/variables.tf`.
6. Outputs necesarios en `envs/prod/outputs.tf`.
7. Riesgos y validación.
