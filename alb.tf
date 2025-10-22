module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name     = "${var.app_name}-alb"
  vpc_id   = module.vpc.vpc_id
  subnets  = module.vpc.public_subnets
  internal = false
  enable_deletion_protection = false
  
  # Security Group
  security_groups = [module.alb_sg.security_group_id]

  # Enable deletion protection for production
  enable_deletion_protection = false  # Set to true for production

  # Access logs - disabled for development
  access_logs = {
    bucket  = "${var.app_name}-alb-logs"
    enabled = false
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "backend"
      }
    }
  }

  target_groups = {
    backend = {
      name_prefix       = "back"
      protocol          = "HTTP"
      port              = 3000
      target_type       = "ip"
      create_attachment = false

      health_check = {
        path                = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        matcher             = "200-399"
      }
    }
  }


  tags = {
    Environment = "Development"
    Project     = var.app_name
  }
}

