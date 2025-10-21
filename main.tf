provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.app_name
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform = "true"
    Application = var.app_name
  }
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb-sg"
  description = "Security group for alb with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules            = ["http-80-tcp", "https-443-tcp"]

  egress_rules = ["all-all"]
}

module "backend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "backend_sg"
  description = "Security group for alb with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Allow port 3000"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  egress_rules = ["all-all"]
}

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "rds-sg"
  description = "Security group for rds with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description = "Allow PostgreSQL from backend"
      rule = "postgresql-tcp"
      source_security_group_id = module.backend_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "matchmarket-db"

  engine            = "postgres"
  engine_version    = "17.4"
  instance_class    = "db.t3.small"
  allocated_storage = 100
  storage_type      = "gp2"
  multi_az          = true
  major_engine_version = "17.4"
  family              = "postgres17"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  tags = {
    Owner       = var.app_name
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  # Database Deletion Protection
  deletion_protection = true

  # Disable Enhanced Monitoring
  monitoring_interval = 0
}