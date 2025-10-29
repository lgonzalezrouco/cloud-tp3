@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo Building Lambda Function
echo ==========================================

set SRC_DIR=%~1
set ZIP_PATH=%~2

if "%SRC_DIR%"=="" set SRC_DIR=./lambda
if "%ZIP_PATH%"=="" set ZIP_PATH=./lambda.zip

if not exist "%SRC_DIR%" (
    echo Error: Lambda source directory not found: %SRC_DIR%
    exit /b 1
)

echo Source directory: %SRC_DIR%
echo Output zip: %ZIP_PATH%

cd /d "%SRC_DIR%"

echo Installing dependencies...
where npm >nul 2>&1
if errorlevel 1 (
    echo Error: npm not found
    exit /b 1
)

echo Done installing dependencies
if errorlevel 1 (
    echo Error: npm install failed
    exit /b 1
)

echo Creating zip file...
powershell -Command "Get-Command Compress-Archive" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell Compress-Archive not found
    exit /b 1
)

if exist "%ZIP_PATH%" del "%ZIP_PATH%"

powershell -Command "Compress-Archive -Path '.\*' -DestinationPath '%ZIP_PATH%' -Force"

if errorlevel 1 (
    echo Error: zip creation failed
    exit /b 1
)

for %%i in ("%ZIP_PATH%") do set ZIP_ABS=%%~fi

echo ==========================================
echo Lambda build completed successfully!
echo Zip file: %ZIP_ABS%
echo ==========================================
