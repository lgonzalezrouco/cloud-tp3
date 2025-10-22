module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "matchmarket-db2"

  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t3.small"
  allocated_storage    = 100
  storage_type         = "gp2"
  # multi_az             = true
  major_engine_version = "17.4"
  family               = "postgres17"

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  manage_master_user_password = false

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  tags = {
    Owner = var.app_name
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  /* # Database Deletion Protection
  deletion_protection = true */

  # Disable Enhanced Monitoring
  monitoring_interval = 0
}

