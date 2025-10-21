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
}