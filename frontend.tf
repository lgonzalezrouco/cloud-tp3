# Recurso para construir el frontend automáticamente
resource "null_resource" "build_frontend" {
  # Trigger: rebuild cuando cambie el DNS del ALB
  triggers = {
    alb_dns = module.alb.dns_name
  }

  # Asegurar que el ALB esté creado antes de construir
  depends_on = [module.alb]

  provisioner "local-exec" {
    # Detectar sistema operativo y usar el script apropiado
    command     = substr(pathexpand("~"), 0, 1) == "/" ? "bash build_frontend.sh ${module.alb.dns_name}" : "build_frontend.bat ${module.alb.dns_name}"
    interpreter = substr(pathexpand("~"), 0, 1) == "/" ? ["bash", "-c"] : ["cmd", "/C"]
  }
}

# Output para mostrar la URL del backend configurada
output "backend_url" {
  description = "URL del backend configurada en el frontend"
  value       = "http://${module.alb.dns_name}"
}

