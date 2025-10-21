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

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Application = var.app_name
  }
}

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

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
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
      description              = "Allow PostgreSQL from backend"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.backend_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

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

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name     = "${var.app_name}-alb"
  vpc_id   = module.vpc.vpc_id
  subnets  = module.vpc.public_subnets
  internal = false

  # Security Group
  security_groups = [module.alb_sg.security_group_id]

  # Access logs opcional
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

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512  # 0.5 vCPU
  memory                   = 1024 # 1 GB RAM

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "emin364/cloud-backend:1.0"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = module.db.db_instance_address
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]
    }
  ])
}

# --- ECS Service ---
resource "aws_ecs_service" "backend" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.backend_sg.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["backend"].arn
    container_name   = "backend"
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}
