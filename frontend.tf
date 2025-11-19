# Recurso para construir el frontend automáticamente
resource "null_resource" "build_frontend" {
  # Trigger: rebuild cuando cambie el DNS del ALB o configuración de Cognito
  triggers = {
    alb_dns           = module.backend_load_balancer.dns_name
    cognito_client_id = aws_cognito_user_pool_client.matchmarket_spa_client.id
    cognito_pool_id   = aws_cognito_user_pool.matchmarket_user_pool.id
  }

  provisioner "local-exec" {
    # Detectar sistema operativo y usar el script apropiado
    # For direct authentication: passing user pool ID and client ID (domain and redirect URI not needed)
    command     = substr(pathexpand("~"), 0, 1) == "/" ? "bash build_frontend.sh ${module.backend_load_balancer.dns_name} https://${module.s3_images_bucket.bucket_id}.s3.${var.aws_region}.amazonaws.com ${aws_cognito_user_pool.matchmarket_user_pool.id} ${aws_cognito_user_pool_client.matchmarket_spa_client.id}" : "build_frontend.bat ${module.backend_load_balancer.dns_name} https://${module.s3_images_bucket.bucket_id}.s3.${var.aws_region}.amazonaws.com ${aws_cognito_user_pool.matchmarket_user_pool.id} ${aws_cognito_user_pool_client.matchmarket_spa_client.id}"
    interpreter = substr(pathexpand("~"), 0, 1) == "/" ? ["bash", "-c"] : ["cmd", "/C"]
  }

  depends_on = [
    module.backend_load_balancer,
    aws_cognito_user_pool_client.matchmarket_spa_client
  ]
}

# Output para mostrar la URL del backend configurada
output "backend_url" {
  description = "URL del backend configurada en el frontend"
  value       = "http://${module.backend_load_balancer.dns_name}"
}

