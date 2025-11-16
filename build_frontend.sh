#!/bin/bash
set -e  # Exit on error

# Variables
FRONTEND_REPO="https://github.com/gcandisano/CloudFront.git"
FRONTEND_DIR="frontend-source"
ALB_URL=$1
IMAGES_BUCKET_URL=$2
COGNITO_USER_POOL_ID=$3
COGNITO_CLIENT_ID=$4

if [ -z "$ALB_URL" ]; then
    echo "Error: ALB URL is required as first argument"
    exit 1
fi

if [ -z "$IMAGES_BUCKET_URL" ]; then
    echo "Error: Images bucket URL is required as second argument"
    exit 1
fi

if [ -z "$COGNITO_USER_POOL_ID" ]; then
    echo "Error: Cognito User Pool ID is required as third argument"
    exit 1
fi

if [ -z "$COGNITO_CLIENT_ID" ]; then
    echo "Error: Cognito Client ID is required as fourth argument"
    exit 1
fi

echo "=========================================="
echo "Building Frontend with Backend URL: $ALB_URL"
echo "Images Bucket URL: $IMAGES_BUCKET_URL"
echo "=========================================="

# Clone or update repository
if [ -d "$FRONTEND_DIR" ]; then
    echo "Updating existing repository..."
    cd "$FRONTEND_DIR"
    git fetch origin
    git reset --hard origin/main
    cd ..
else
    echo "Cloning repository..."
    git clone "$FRONTEND_REPO" "$FRONTEND_DIR"
fi

cd "$FRONTEND_DIR"

# Create .env file with required configuration
echo "Creating .env file..."
cat > .env << EOF
# AWS Cognito Configuration
VITE_COGNITO_USER_POOL_ID=${COGNITO_USER_POOL_ID}
VITE_COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID}

# S3 Configuration
VITE_S3_URL=${IMAGES_BUCKET_URL}

# API BASE URL
VITE_API_BASE_URL=http://${ALB_URL}
EOF

echo "Installing dependencies..."
npm install

echo "Building frontend..."
npm run build

echo "Copying build files to dist directory..."
cd ..
# Create dist directory if it doesn't exist
mkdir -p dist
rm -rf dist/*
cp -r "$FRONTEND_DIR/dist/"* dist/

echo "=========================================="
echo "Frontend build completed successfully!"
echo "Backend URL: http://${ALB_URL}"
echo "=========================================="

