output "website_url" {
  description = "URL del sitio web estático en S3"
  value       = "http://${module.s3_bucket.bucket_name}.s3-website-${var.aws_region}.amazonaws.com"
}

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.s3_bucket.bucket_name
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = module.alb.dns_name
}

output "db_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = module.db.db_instance_endpoint
}

output "cloudwatch_log_group" {
  description = "Nombre del CloudWatch Log Group para los logs de ECS"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "cloudwatch_logs_url" {
  description = "URL directa para ver los logs en la consola de AWS"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.ecs_logs.name, "/", "$252F")}"
}

# ECR Outputs
output "ecr_repository_name" {
  description = "Nombre del repositorio ECR del backend"
  value       = aws_ecr_repository.backend.name
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR del backend"
  value       = aws_ecr_repository.backend.repository_url
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.backend.name
}

output "app_name" {
  description = "Nombre de la aplicación"
  value       = var.app_name
}

output "aws_region" {
  description = "Región de AWS"
  value       = var.aws_region
}

output "images_bucket_name" {
  description = "Name of the S3 bucket for product images"
  value       = module.s3_images_bucket.bucket_id
}

output "images_bucket_url" {
  description = "URL of the S3 bucket for product images"
  value       = "https://${module.s3_images_bucket.bucket_id}.s3.${var.aws_region}.amazonaws.com"
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.matchmarket_user_pool.id
}

output "cognito_app_client_id" {
  description = "The ID of the Cognito App Client."
  value       = aws_cognito_user_pool_client.matchmarket_spa_client.id
}

output "cognito_region" {
  description = "AWS region where Cognito is deployed"
  value       = var.aws_region
}


output "newsletter_sns_topic_arn" {
  description = "ARN del topic SNS para newsletter"
  value       = aws_sns_topic.product_newsletter.arn
}
