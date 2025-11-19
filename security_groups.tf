module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb-sg"
  description = "Security group for alb with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_rules = ["all-all"]
}

module "backend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "backend_sg"
  description = "Security group for alb with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  # This is the corrected block
  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Allow traffic from ALB"
      source_security_group_id = module.alb_sg.security_group_id
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
      description              = "Allow PostgreSQL from backend"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.backend_sg.security_group_id
    },
    {
      description              = "Allow PostgreSQL from newsletter Lambda"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.newsletter_lambda_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}