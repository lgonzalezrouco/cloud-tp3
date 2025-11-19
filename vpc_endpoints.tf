# --- Local: Select one subnet per AZ for VPC endpoints ---
locals {
  # Get the AZs used by the VPC module (first 2 AZs)
  vpc_azs = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Get subnet objects to check availability zones
  private_subnet_objects = module.vpc.private_subnet_objects
  
  # Group subnets by availability zone and select the first one from each AZ
  # This ensures we have exactly one subnet per availability zone
  vpc_endpoint_subnets = [
    for az in local.vpc_azs :
    [for subnet in local.private_subnet_objects : subnet.id if subnet.availability_zone == az][0]
  ]
}

# --- Security Group for VPC Endpoints ---
module "vpc_endpoints_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.vpc_cidr]
  ingress_rules       = ["https-443-tcp"]

  egress_rules = ["all-all"]

  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}

# --- VPC Endpoints Module ---
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = {
    # S3 Gateway Endpoint (free, no data transfer charges)
    # Gateway endpoints usan route_table_ids (no subnet_ids ni security groups)
    # Se agregan como rutas en las tablas de enrutamiento
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name        = "${var.app_name}-s3-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }

    # ECR API Interface Endpoint (for pulling container images)
    # Interface endpoints usan subnet_ids (no route_table_ids)
    # Se despliegan como interfaces de red EN las subnets
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = local.vpc_endpoint_subnets
      tags = {
        Name        = "${var.app_name}-ecr-api-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }

    # ECR DKR Interface Endpoint (for pulling container images)
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = local.vpc_endpoint_subnets
      tags = {
        Name        = "${var.app_name}-ecr-dkr-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }

    # ECS Interface Endpoint (for ECS API calls)
    ecs = {
      service             = "ecs"
      private_dns_enabled = true
      subnet_ids          = local.vpc_endpoint_subnets
      tags = {
        Name        = "${var.app_name}-ecs-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }

    # CloudWatch Logs Interface Endpoint (for logging)
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = local.vpc_endpoint_subnets
      tags = {
        Name        = "${var.app_name}-logs-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }

    # SNS Interface Endpoint (for notifications)
    sns = {
      service             = "sns"
      private_dns_enabled = true
      subnet_ids          = local.vpc_endpoint_subnets
      tags = {
        Name        = "${var.app_name}-sns-endpoint"
        Application = var.app_name
        Environment = var.environment
      }
    }
  }

  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}

