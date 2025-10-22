#!/bin/bash
set -e  # Exit on error

# Variables
FRONTEND_REPO="https://github.com/gcandisano/CloudFront.git"
FRONTEND_DIR="frontend-source"
ALB_URL=$1

if [ -z "$ALB_URL" ]; then
    echo "Error: ALB URL is required as first argument"
    exit 1
fi

echo "=========================================="
echo "Building Frontend with Backend URL: $ALB_URL"
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

# Create .env file with ALB URL
echo "Creating .env file..."
cat > .env << EOF
VITE_API_BASE_URL=${ALB_URL}
VITE_APP_TITLE=Match Market
VITE_APP_DESCRIPTION=Tu marketplace de confianza
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
echo "Backend URL: ${ALB_URL}"
echo "=========================================="