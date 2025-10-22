variable "lambda_functions" {
  description = "Mapa: key -> { filename, handler, runtime, env }"
  type = map(object({
    filename = string          # ruta al .zip
    handler  = string          # p.ej: app.handler
    runtime  = string          # p.ej: python3.12
    env      = map(string)     # variables de entorno
  }))
}

variable "vpc_subnet_ids" {
  description = "Subnets para las Lambdas (VPC)"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security Groups para las Lambdas"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefijo para nombres de funciones"
  type        = string
  default     = "app"
}

variable "lambda_role" {
  description = "ARN del rol EXISTENTE que usarán TODAS las Lambdas"
  type        = string
}
