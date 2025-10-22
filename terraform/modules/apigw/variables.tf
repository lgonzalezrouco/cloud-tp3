variable "name" {}
variable "routes" { # map(object({ route_key=string, lambda_arn=string, auth=optional(string) }))
  type = map(object({
    route_key  = string
    lambda_arn = string
    auth       = optional(string) # "JWT" | "NONE"
  }))
}
variable "jwt_authorizer" {
  type    = object({ issuer = string, audiences = list(string) })
  default = null
}
