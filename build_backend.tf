# Build y push del backend a ECR usando script multiplataforma

resource "null_resource" "backend_image" {
  # Solo construir si no se usa Docker Hub
  count = var.use_dockerhub ? 0 : 1

  triggers = {
    ecr_repository_url = aws_ecr_repository.backend.repository_url
    is_windows         = substr(pathexpand("~"), 0, 1) == "/" ? "false" : "true"
    # Cambiar esto si quieres forzar rebuild: timestamp()
    force_rebuild = "v4"
  }

  # Ejecutar script apropiado según el sistema operativo
  provisioner "local-exec" {
    # Windows: usa PowerShell con parámetros, Linux/Mac: usa bash con variables de entorno
    command = self.triggers.is_windows == "true" ? "powershell -ExecutionPolicy Bypass -File scripts/build_backend.ps1 ${aws_ecr_repository.backend.repository_url} ${var.aws_region}" : "bash scripts/build_backend.sh"
    
    environment = {
      ECR_REPO_URL = aws_ecr_repository.backend.repository_url
      AWS_REGION   = var.aws_region
    }
  }

  depends_on = [aws_ecr_repository.backend]
}

resource "time_sleep" "wait_for_backend_image" {
  count = var.use_dockerhub ? 0 : 1

  depends_on      = [null_resource.backend_image[0]]
  create_duration = "15s"
}

