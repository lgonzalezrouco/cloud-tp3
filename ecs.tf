# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"  # Enable Container Insights for better monitoring
  }

  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512  # 0.5 vCPU
  memory                   = 1024 # 1 GB RAM
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.use_dockerhub ? var.dockerhub_image : "${aws_ecr_repository.backend.repository_url}:latest"
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
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_S3_BUCKET"
          value = "${var.s3_bucket_name}-images"
        },
        {
          name  = "COGNITO_USER_POOL_ID"
          value = aws_cognito_user_pool.matchmarket_user_pool.id
        },
        {
          name  = "COGNITO_CLIENT_ID"
          value = aws_cognito_user_pool_client.matchmarket_spa_client.id
        },
        {
          name  = "COGNITO_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_SNS_TOPIC_ARN"
          value = aws_sns_topic.product_newsletter.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
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
    subnets          = [module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_groups  = [module.backend_sg.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.backend_load_balancer.target_groups["backend"].arn
    container_name   = "backend"
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  # Enable service discovery and better health checks
  health_check_grace_period_seconds = 60

  tags = {
    Application = var.app_name
    Environment = var.environment
  }

  # Ensure ALB and database are ready before deploying service
  depends_on = [
    module.backend_load_balancer,
    module.db
  ]
}

