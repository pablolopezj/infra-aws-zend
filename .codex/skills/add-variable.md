# Skill: Add Terraform Variable

## Objetivo

Agregar una variable Terraform correctamente documentada y validada.

## Template recomendado

```hcl
variable "example_variable" {
  description = "Descripción clara de la variable."
  type        = string
  default     = "default-value"

  validation {
    condition     = length(var.example_variable) > 0
    error_message = "example_variable no puede estar vacío."
  }
}
```

## Para booleanos

```hcl
variable "enable_feature" {
  description = "Habilita o deshabilita la funcionalidad."
  type        = bool
  default     = false
}
```

## Para listas

```hcl
variable "allowed_cidrs" {
  description = "Lista de CIDRs permitidos."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Todos los valores deben ser CIDRs válidos."
  }
}
```

## Reglas

- Siempre usar `description`.
- Siempre usar `type`.
- Usar `default` solo si tiene sentido.
- Usar `validation` para valores peligrosos o restringidos.
- No usar variables para secretos en texto plano.
