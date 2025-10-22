#!/bin/bash
# Script multiplataforma para construir y subir backend a ECR
set -e

echo "=========================================="
echo "Building Backend Image for ECR"
echo "=========================================="

REPO_URL="https://github.com/EmiN364/CloudBackEnd.git"
BUILD_DIR="backend-source"

# Limpiar directorio anterior
echo "[1/5] Cleaning previous build..."
rm -rf "$BUILD_DIR"

# Clonar repositorio
echo "[2/5] Cloning backend repository..."
git clone "$REPO_URL" "$BUILD_DIR"

# Login a ECR
echo "[3/5] Logging in to ECR..."
ECR_REGISTRY=$(echo "$ECR_REPO_URL" | cut -d'/' -f1)
echo "Registry: $ECR_REGISTRY"
if ! aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
    echo "ERROR: Failed to login to ECR"
    exit 1
fi
echo "Successfully logged in to ECR"

# Build
echo "[4/5] Building Docker image..."
cd "$BUILD_DIR"
docker build -t "$ECR_REPO_URL:latest" .

# Push
echo "[5/5] Pushing to ECR..."
docker push "$ECR_REPO_URL:latest"

cd ..

echo "=========================================="
echo "✓ Backend image built and pushed!"
echo "=========================================="



