@echo off
setlocal EnableDelayedExpansion

REM Variables
set FRONTEND_REPO=https://github.com/gcandisano/CloudFront.git
set FRONTEND_DIR=frontend-source
set ALB_URL=%1
set IMAGES_BUCKET_URL=%2
set COGNITO_USER_POOL_ID=%3
set COGNITO_CLIENT_ID=%4

if "%ALB_URL%"=="" (
    echo Error: ALB URL is required as first argument
    exit /b 1
)

if "%IMAGES_BUCKET_URL%"=="" (
    echo Error: Images bucket URL is required as second argument
    exit /b 1
)

if "%COGNITO_USER_POOL_ID%"=="" (
    echo Error: Cognito User Pool ID is required as third argument
    exit /b 1
)

if "%COGNITO_CLIENT_ID%"=="" (
    echo Error: Cognito Client ID is required as fourth argument
    exit /b 1
)

echo ==========================================
echo Building Frontend with Backend URL: %ALB_URL%
echo Images Bucket URL: %IMAGES_BUCKET_URL%
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

REM Create .env file with required configuration
echo Creating .env file...
(
echo # AWS Cognito Configuration
echo VITE_COGNITO_USER_POOL_ID=%COGNITO_USER_POOL_ID%
echo VITE_COGNITO_CLIENT_ID=%COGNITO_CLIENT_ID%
echo.
echo # S3 Configuration
echo VITE_S3_URL=%IMAGES_BUCKET_URL%
echo.
echo # API BASE URL
echo VITE_API_BASE_URL=http://%ALB_URL%
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
REM Create dist directory if it doesn't exist
if not exist "dist" (
    mkdir dist
)
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

