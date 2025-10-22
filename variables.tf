variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region to deploy example API Gateway REST API"
  type        = string
}

variable "app_name" {
  default     = "MatchMarket"
  description = "Name of the application"
  type        = string
}

variable "db_name" {
  default     = "matchmarket"
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  default     = "postgres"
  description = "Username of the database"
  type        = string
}

variable "db_password" {
  default     = "tp-cloud-g7"
  description = "Password of the database"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "use_dockerhub" {
  default     = false
  description = "Si true, usa imagen de Docker Hub. Si false, construye y sube a ECR (requiere Docker instalado)"
  type        = bool
}

variable "dockerhub_image" {
  default     = "emin364/cloud-backend:latest"
  description = "Imagen de Docker Hub a usar cuando use_dockerhub = true"
  type        = string
}

variable "cognito_domain" {
  description = "Cognito domain prefix (ej: mi-userpool)"
  type        = string
  default     = "cognito-domain"
}

variable "cognito_client_id" {
  description = "Client ID de la app cliente en Cognito"
  type        = string
  default     = "client-id"
}

variable "client_secret" {
  description = "Client secret (opcional). Si está vacío, puede usarse client_secret_arn."
  type        = string
  default     = "client-secret"
  sensitive   = true
}

variable "client_secret_arn" {
  description = "ARN del secreto en AWS Secrets Manager que contiene el client secret (opcional)"
  type        = string
  default     = ""
}

variable "cognito_redirect_uri" {
  description = "Redirect URI base (sin /callback) que configuraste en Cognito"
  type        = string
  default     = "redirect-uri"
}

variable "frontend_url" {
  description = "URL pública del frontend para hacer el redirect con tokens"
  type        = string
  default     = "frontend-url"
}