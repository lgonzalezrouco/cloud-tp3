terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.29.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}