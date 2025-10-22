module "s3_bucket" {
  source              = "./modules/s3"
  bucket_name         = "matchmarket-testing-emi"
  block_public_access = false # Permitir acceso público para el sitio web
  tags = {
    Owner = var.app_name
  }
}

# Configuración de website hosting
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = module.s3_bucket.bucket_id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Bucket policy para permitir acceso público de lectura
resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.s3_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.s3_bucket.bucket_arn}/*"
      }
    ]
  })
}

# Subir index.html
resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.bucket_id
  key          = "index.html"
  source       = "dist/index.html"
  content_type = "text/html"
  etag         = filemd5("dist/index.html")

  # Asegurar que el frontend esté construido antes de subir
  depends_on = [null_resource.build_frontend]
}

# Subir favicon.ico
resource "aws_s3_object" "favicon" {
  bucket       = module.s3_bucket.bucket_id
  key          = "favicon.ico"
  source       = "dist/favicon.ico"
  content_type = "image/x-icon"
  etag         = filemd5("dist/favicon.ico")

  depends_on = [null_resource.build_frontend]
}

# Subir archivos CSS de assets
resource "aws_s3_object" "css_files" {
  for_each = fileset("dist/assets", "*.css")

  bucket       = module.s3_bucket.bucket_id
  key          = "assets/${each.value}"
  source       = "dist/assets/${each.value}"
  content_type = "text/css"
  etag         = filemd5("dist/assets/${each.value}")

  depends_on = [null_resource.build_frontend]
}

# Subir archivos JS de assets
resource "aws_s3_object" "js_files" {
  for_each = fileset("dist/assets", "*.js")

  bucket       = module.s3_bucket.bucket_id
  key          = "assets/${each.value}"
  source       = "dist/assets/${each.value}"
  content_type = "application/javascript"
  etag         = filemd5("dist/assets/${each.value}")

  depends_on = [null_resource.build_frontend]
}
