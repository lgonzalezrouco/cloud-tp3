########################################
# Rol existente del Learner Lab
########################################
data "aws_iam_role" "labrole" {
  name = "LabRole"
}

########################################
# VPC (módulo oficial) - simple
########################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.app_name
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Project = var.app_name }
}

########################################
# SGs: DB y Lambda
########################################
resource "aws_security_group" "lambda" {
  name        = "${var.app_name}-lambda-sg"
  description = "SG for Lambdas"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Project = var.app_name }
}

resource "aws_security_group" "db" {
  name        = "${var.app_name}-db-sg"
  description = "SG for RDS Postgres"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description              = "Postgres from Lambda SG"
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    security_groups          = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Project = var.app_name }
}

########################################
# RDS Postgres (privado)
########################################
resource "aws_db_subnet_group" "db" {
  name       = "${var.app_name}-db-subnets"
  subnet_ids = module.vpc.private_subnets
  tags       = { Name = "${var.app_name}-db-subnets" }
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.app_name}-postgres"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.small"
  allocated_storage       = 100
  storage_type            = "gp2"
  multi_az                = true

  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 5432

  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.db.name

  monitoring_interval     = 0
  performance_insights_enabled = false

  deletion_protection     = false
  skip_final_snapshot     = true

  tags = { Project = var.app_name }
}

########################################
# Módulo de Lambda (usa SIEMPRE rol existente)
########################################
module "lambda" {
  source = "./modules/lambda"

  name_prefix            = var.app_name
  lambda_functions       = local.lambda_functions

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda.id]

  lambda_role            = data.aws_iam_role.labrole.arn
  depends_on             = [aws_db_instance.postgres]
}

########################################
# Invocar init_schema automáticamente (Opción A)
########################################
data "aws_lambda_invocation" "run_init" {
  function_name = module.lambda.function_names["init_schema"]
  input         = jsonencode({ "action" = "apply_schema" })

  depends_on = [
    module.lambda,
    aws_db_instance.postgres
  ]
}

module "api" {
  source = "./modules/apigw"
  name   = var.app_name
  routes = local.api_routes

  jwt_authorizer = {
    issuer    = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
    audiences = [aws_cognito_user_pool_client.this.id]
  }

  depends_on = [module.lambda]
}

# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "this" {
  name = "${var.app_name}-up"

  # login por email
  alias_attributes = ["email"]
  auto_verified_attributes = ["email"]

  # políticas simples (ajustá a tu gusto)
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # sólo para lab/demos (signup abierto)
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

# --- App client (no secret, para web/app SPA) ---
resource "aws_cognito_user_pool_client" "this" {
  name                         = "${var.app_name}-client"
  user_pool_id                 = aws_cognito_user_pool.this.id
  generate_secret              = false
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
  callback_urls                = ["https://example.com/callback"]  # ajustá
  logout_urls                  = ["https://example.com/logout"]    # ajustá
}

# --- Domain (opcional, para alojar el Hosted UI) ---
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.app_name}-auth-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "random_id" "suffix" { byte_length = 3 }
