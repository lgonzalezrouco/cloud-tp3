# Recurso para construir el frontend automáticamente
resource "null_resource" "build_frontend" {
  # Trigger: rebuild cuando cambie el DNS del ALB
  triggers = {
    alb_dns = module.alb.dns_name
  }

  # Asegurar que el ALB esté creado antes de construir
  depends_on = [module.alb, aws_cognito_user_pool_domain.main, aws_cognito_user_pool_client.main, aws_apigatewayv2_api.callback_api, aws_apigatewayv2_stage.prod]

  provisioner "local-exec" {
    # Detectar sistema operativo y usar el script apropiado
    command     = substr(pathexpand("~"), 0, 1) == "/" ? "bash build_frontend.sh ${module.alb.dns_name} https://${module.s3_images_bucket.bucket_id}.s3.${var.aws_region}.amazonaws.com ${aws_cognito_user_pool_domain.main.domain} ${aws_cognito_user_pool_client.main.id} ${aws_apigatewayv2_api.callback_api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}/callback" : "build_frontend.bat ${module.alb.dns_name} https://${module.s3_images_bucket.bucket_id}.s3.${var.aws_region}.amazonaws.com ${aws_cognito_user_pool_domain.main.domain} ${aws_cognito_user_pool_client.main.id} ${aws_apigatewayv2_api.callback_api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}/callback"
    interpreter = substr(pathexpand("~"), 0, 1) == "/" ? ["bash", "-c"] : ["cmd", "/C"]
  }
}

# Output para mostrar la URL del backend configurada
output "backend_url" {
  description = "URL del backend configurada en el frontend"
  value       = "http://${module.alb.dns_name}"
}

