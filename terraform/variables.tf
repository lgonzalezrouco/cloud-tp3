variable "region" { 
  type = string  
  default = "us-east-1" 
}


variable "app_name" {
  default     = "matchmarket"
  description = "Name of the application"
  type        = string
}

variable "db_name" {
  default     = "matchmarket"
  description = "Name of the database"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket para el frontend"
  type        = string
  default     = null
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
}