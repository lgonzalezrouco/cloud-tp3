# Recurso para construir el frontend automáticamente
resource "null_resource" "build_frontend" {
  # Trigger: rebuild cuando cambie el DNS del ALB
  triggers = {
    alb_dns = module.api.api_endpoint
  }

  # Asegurar que el ALB esté creado antes de construir
  depends_on = [module.api]

  provisioner "local-exec" {
    # Detectar sistema operativo y usar el script apropiado
    command     = substr(pathexpand("~"), 0, 1) == "/" ? "bash build_frontend.sh ${module.api.api_endpoint}" : "build_frontend.bat ${module.api.api_endpoint}"
    interpreter = substr(pathexpand("~"), 0, 1) == "/" ? ["bash", "-c"] : ["cmd", "/C"]
  }
}

# Output para mostrar la URL del backend configurada
output "frontend_backend_url" {
  description = "URL del backend configurada en el frontend"
  value       = "${module.api.api_endpoint}"
}