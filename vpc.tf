locals {
  az_count = 2
  # Generar dinámicamente los CIDRs de las subnets usando cidrsubnet()
  # Private subnets: 4 subnets (2 para cada AZ)
  private_subnets = [
    for i in range(local.az_count * 2) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  # Public subnets: 2 subnets (1 para cada AZ)
  public_subnets = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.app_name
  cidr = var.vpc_cidr

  # Use data source for AZs instead of hardcoding
  azs             = slice(data.aws_availability_zones.available.names, 0, local.az_count)
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Application = var.app_name
  }
}

