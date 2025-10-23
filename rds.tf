module "db" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = "matchmarket-db2"

  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t3.small"
  allocated_storage    = 20
  max_allocated_storage = 100            # Auto-scaling enabled up to 100GB
  storage_type         = "gp2"
  major_engine_version = "17.4"
  family               = "postgres17"
  multi_az             = true

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  manage_master_user_password = false

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  tags = {
    Owner       = var.app_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[2], module.vpc.private_subnets[3]]
  
  # Performance Insights
  performance_insights_enabled = false  # Set to true for production monitoring
  
  # Database Deletion Protection - enable for production
  deletion_protection = false  # Set to true for production

  # Disable Enhanced Monitoring for cost savings
  monitoring_interval = 0
  
  # Apply changes immediately (set to false for production)
  apply_immediately = true
}

