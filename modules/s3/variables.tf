variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "enable_versioning" {
  description = "Habilitar versionado del bucket"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Habilitar encriptación del bucket"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Bloquear acceso público al bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para el bucket S3"
  type        = map(string)
  default     = {}
}

