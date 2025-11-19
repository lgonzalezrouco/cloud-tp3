$ErrorActionPreference = "Stop"

$LambdaDir = "lambda-source\product-newsletter"
$BuildDir = "builds\lambda-package"
$OutputZip = "builds\newsletter-lambda.zip"

Write-Host "Limpiando directorio anterior..." -ForegroundColor Yellow
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
if (Test-Path $OutputZip) {
    Remove-Item -Force $OutputZip
}

Write-Host "Creando directorio de build..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path "builds" | Out-Null

Write-Host "Copiando codigo fuente..." -ForegroundColor Yellow
Copy-Item "$LambdaDir\handler.py" -Destination $BuildDir

Write-Host "Instalando dependencias..." -ForegroundColor Cyan
pip install -r "$LambdaDir\requirements.txt" -t $BuildDir --platform manylinux2014_x86_64 --implementation cp --python-version 3.11 --only-binary=:all: --upgrade

Write-Host "Verificando instalacion de psycopg2..." -ForegroundColor Yellow
if (Test-Path "$BuildDir\psycopg2") {
    Write-Host "psycopg2 instalado correctamente" -ForegroundColor Green
} else {
    Write-Host "ERROR: psycopg2 no se instalo" -ForegroundColor Red
    exit 1
}

Write-Host "Creando archivo ZIP..." -ForegroundColor Cyan
$source = Resolve-Path $BuildDir
Compress-Archive -Path "$source\*" -DestinationPath $OutputZip -Force

$zipSize = (Get-Item $OutputZip).Length / 1MB
Write-Host "Lambda empaquetada: $OutputZip ($('{0:N2}' -f $zipSize) MB)" -ForegroundColor Green
