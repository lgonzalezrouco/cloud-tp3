#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building Lambda Function"
echo "=========================================="

SRC_DIR="${1:-./lambda}"
ZIP_PATH="${2:-./lambda.zip}"

if [ ! -d "${SRC_DIR}" ]; then
  echo "Error: Lambda source directory not found: ${SRC_DIR}"
  exit 1
fi

echo "Source directory: ${SRC_DIR}"
echo "Output zip: ${ZIP_PATH}"

cd "${SRC_DIR}"

echo "Installing dependencies..."
if command -v npm >/dev/null 2>&1; then
  if [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
    npm ci --omit=dev
  else
    npm install --production
  fi
else
  echo "Error: npm not found"
  exit 1
fi

echo "Creating zip file..."
if ! command -v zip >/dev/null 2>&1; then
  echo "Error: zip command not found"
  exit 1
fi

rm -f "${ZIP_PATH}"

ZIP_ABS="$(cd "$(dirname "${ZIP_PATH}")" && pwd)/$(basename "${ZIP_PATH}")"
zip -r "${ZIP_ABS}" . > /dev/null 2>&1

echo "=========================================="
echo "Lambda build completed successfully!"
echo "Zip file: ${ZIP_ABS}"
echo "=========================================="