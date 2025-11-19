data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Script para empaquetar Lambda con dependencias
resource "null_resource" "package_newsletter_lambda" {
  triggers = {
    handler_hash      = filemd5("${path.module}/lambda-source/product-newsletter/handler.py")
    requirements_hash = filemd5("${path.module}/lambda-source/product-newsletter/requirements.txt")
    is_windows        = substr(pathexpand("~"), 0, 1) == "/" ? "false" : "true"
  }

  provisioner "local-exec" {
    command     = self.triggers.is_windows == "true" ? "powershell -ExecutionPolicy Bypass -File scripts/package_lambda.ps1" : "bash scripts/package_lambda.sh"
    working_dir = path.module
  }
}

# Esperar a que el paquete este listo
resource "time_sleep" "wait_for_package" {
  depends_on      = [null_resource.package_newsletter_lambda]
  create_duration = "10s"
}

# Data source para el archivo zip (esto calcula el hash correctamente)
data "archive_file" "newsletter_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/builds/lambda-package"
  output_path = "${path.module}/builds/newsletter-lambda-terraform.zip"

  depends_on = [time_sleep.wait_for_package]
}

# Funcion Lambda
resource "aws_lambda_function" "product_newsletter" {
  filename         = "${path.module}/builds/newsletter-lambda.zip"
  function_name    = "product-newsletter"
  role            = data.aws_iam_role.lab_role.arn
  handler         = "handler.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 256
  source_code_hash = data.archive_file.newsletter_lambda_zip.output_base64sha256

  environment {
    variables = {
      DB_HOST       = module.db.db_instance_address
      DB_NAME       = var.db_name
      DB_USER       = var.db_username
      DB_PASSWORD   = var.db_password
      SNS_TOPIC_ARN = aws_sns_topic.product_newsletter.arn
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.newsletter_lambda_sg.security_group_id]
  }

  depends_on = [
    data.archive_file.newsletter_lambda_zip,
    module.db,
    aws_sns_topic.product_newsletter
  ]
}

resource "aws_sns_topic" "product_newsletter" {
  name = "product-newsletter-topic"
}

module "newsletter_lambda_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "newsletter-lambda-sg"
  description = "Security group for newsletter Lambda"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]
}
