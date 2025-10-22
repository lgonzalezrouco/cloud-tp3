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

