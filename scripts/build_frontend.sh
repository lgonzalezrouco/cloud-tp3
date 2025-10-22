#!/bin/bash
# Script multiplataforma para construir y subir frontend a S3
set -e

echo "=========================================="
echo "Building Frontend for S3"
echo "=========================================="

# Obtener ALB URL desde Terraform
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null)
if [ -z "$ALB_DNS" ]; then
    echo "ERROR: No se pudo obtener ALB DNS"
    echo "Ejecuta 'terraform apply' primero"
    exit 1
fi

BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null)
if [ -z "$BUCKET_NAME" ]; then
    echo "ERROR: No se pudo obtener bucket name"
    exit 1
fi

API_URL="http://${ALB_DNS}/api"

echo "API URL: $API_URL"
echo "S3 Bucket: $BUCKET_NAME"

# Ir al directorio del frontend
cd frontend-source

# Crear archivo .env con la API URL
echo "[1/4] Creating .env file..."
cat > .env << EOF
VITE_API_URL=$API_URL
EOF

# Instalar dependencias
echo "[2/4] Installing dependencies..."
npm install

# Build
echo "[3/4] Building frontend..."
npm run build

# Subir a S3
echo "[4/4] Uploading to S3..."
aws s3 sync dist/ s3://$BUCKET_NAME/ --delete

cd ..

echo "=========================================="
echo "✓ Frontend built and uploaded!"
echo "=========================================="
echo "Website URL: http://${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com"



