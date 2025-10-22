@echo off
setlocal EnableDelayedExpansion

REM Variables
set FRONTEND_REPO=https://github.com/gcandisano/CloudFront.git
set FRONTEND_DIR=frontend-source
set ALB_URL=%1

if "%ALB_URL%"=="" (
    echo Error: ALB URL is required as first argument
    exit /b 1
)

echo ==========================================
echo Building Frontend with Backend URL: %ALB_URL%
echo ==========================================

REM Clone or update repository
if exist "%FRONTEND_DIR%" (
    echo Updating existing repository...
    cd "%FRONTEND_DIR%"
    git fetch origin
    git reset --hard origin/main
    cd ..
) else (
    echo Cloning repository...
    git clone "%FRONTEND_REPO%" "%FRONTEND_DIR%"
)

cd "%FRONTEND_DIR%"

REM Create .env file with ALB URL
echo Creating .env file...
(
echo VITE_API_BASE_URL=http://%ALB_URL%
echo VITE_APP_TITLE=Match Market
echo VITE_APP_DESCRIPTION=Tu marketplace de confianza
) > .env

echo Installing dependencies...
call npm install
if errorlevel 1 (
    echo Error: npm install failed
    exit /b 1
)

echo Building frontend...
call npm run build
if errorlevel 1 (
    echo Error: npm build failed
    exit /b 1
)

echo Copying build files to dist directory...
cd ..
if exist "dist" (
    rmdir /s /q dist
)
mkdir dist
xcopy /E /I /Y "%FRONTEND_DIR%\dist\*" "dist\"

echo ==========================================
echo Frontend build completed successfully!
echo Backend URL: http://%ALB_URL%
echo ==========================================

endlocal

