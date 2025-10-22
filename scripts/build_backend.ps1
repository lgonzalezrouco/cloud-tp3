# PowerShell script para Windows
param(
    [string]$ECR_REPO_URL,
    [string]$AWS_REGION
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building Backend Image for ECR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$REPO_URL = "https://github.com/EmiN364/CloudBackEnd.git"
$BUILD_DIR = "backend-source"

Write-Host "ECR URL: $ECR_REPO_URL" -ForegroundColor Cyan
Write-Host "Region: $AWS_REGION" -ForegroundColor Cyan

# Limpiar directorio anterior
Write-Host "[1/5] Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path $BUILD_DIR) {
    Remove-Item -Recurse -Force $BUILD_DIR
}

# Clonar repositorio
Write-Host "[2/5] Cloning backend repository..." -ForegroundColor Yellow
git clone $REPO_URL $BUILD_DIR
if ($LASTEXITCODE -ne 0) { exit 1 }

# Login a ECR
Write-Host "[3/5] Logging in to ECR..." -ForegroundColor Yellow
$ECR_REGISTRY = $ECR_REPO_URL.Split('/')[0]

$loginPassword = aws ecr get-login-password --region $AWS_REGION
if ($LASTEXITCODE -ne 0) { 
    Write-Host "ERROR: Failed to retrieve login password" -ForegroundColor Red
    exit 1 
}
Write-Host "Login password: $loginPassword" -ForegroundColor Yellow

# Usar invoke expression para ejecutar el comando completo con pipe
$loginCommand = "aws ecr get-login-password --region $($AWS_REGION) | docker login --username AWS --password $loginPassword $ECR_REGISTRY"
Write-Host "Login command: $loginCommand" -ForegroundColor Yellow
Invoke-Expression $loginCommand
if ($LASTEXITCODE -ne 0) { 
    Write-Host "ERROR: Failed to login to ECR" -ForegroundColor Red
    exit 1 
}

# Build
Write-Host "[4/5] Building Docker image..." -ForegroundColor Yellow
Set-Location $BUILD_DIR
docker build -t "$($ECR_REPO_URL):latest" .
if ($LASTEXITCODE -ne 0) { exit 1 }

# Push
Write-Host "[5/5] Pushing to ECR..." -ForegroundColor Yellow
docker push "$($ECR_REPO_URL):latest"
if ($LASTEXITCODE -ne 0) { exit 1 }

Set-Location ..

Write-Host "==========================================" -ForegroundColor Green
Write-Host "SUCCESS: Backend image built and pushed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

