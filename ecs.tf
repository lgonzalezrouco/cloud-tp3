# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    Application = var.app_name
    Environment = "production"
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
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

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
        },
        {
          name: "AWS_ACCESS_KEY_ID",
          value: data.aws_caller_identity.current.account_id
        },
        {
          name: "AWS_SECRET_ACCESS_KEY",
          value: data.aws_caller_identity.current.secret_access_key
        },
        {
          name: "AWS_S3_BUCKET",
          value: var.s3_bucket_name
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

  # Asegurar que el ALB y la base de datos estén listos antes de iniciar el servicio
  depends_on = [module.alb, module.db]
}

