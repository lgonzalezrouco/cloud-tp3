# PowerShell script para build del frontend en Windows
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building Frontend for S3" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Obtener ALB URL desde Terraform
$ALB_DNS = terraform output -raw alb_dns_name 2>$null
if ([string]::IsNullOrEmpty($ALB_DNS)) {
    Write-Host "ERROR: No se pudo obtener ALB DNS" -ForegroundColor Red
    Write-Host "Ejecuta 'terraform apply' primero" -ForegroundColor Red
    exit 1
}

$BUCKET_NAME = terraform output -raw bucket_name 2>$null
if ([string]::IsNullOrEmpty($BUCKET_NAME)) {
    Write-Host "ERROR: No se pudo obtener bucket name" -ForegroundColor Red
    exit 1
}

$API_URL = "http://$ALB_DNS/api"

Write-Host "API URL: $API_URL" -ForegroundColor Green
Write-Host "S3 Bucket: $BUCKET_NAME" -ForegroundColor Green

# Ir al directorio del frontend
Set-Location frontend-source

# Crear archivo .env
Write-Host "[1/4] Creating .env file..." -ForegroundColor Yellow
"VITE_API_URL=$API_URL" | Out-File -FilePath .env -Encoding utf8

# Instalar dependencias
Write-Host "[2/4] Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) { exit 1 }

# Build
Write-Host "[3/4] Building frontend..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) { exit 1 }

# Subir a S3
Write-Host "[4/4] Uploading to S3..." -ForegroundColor Yellow
aws s3 sync dist/ "s3://$BUCKET_NAME/" --delete
if ($LASTEXITCODE -ne 0) { exit 1 }

Set-Location ..

Write-Host "==========================================" -ForegroundColor Green
Write-Host "SUCCESS: Frontend built and uploaded!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Website URL: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan

