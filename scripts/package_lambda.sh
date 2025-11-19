#!/bin/bash
set -e

LAMBDA_DIR="lambda-source/product-newsletter"
BUILD_DIR="builds/lambda-package"
OUTPUT_ZIP="builds/newsletter-lambda.zip"

echo "Limpiando directorio anterior..."
rm -rf "$BUILD_DIR"
rm -f "$OUTPUT_ZIP"

echo "Creando directorio de build..."
mkdir -p "$BUILD_DIR"
mkdir -p "builds"

echo "Copiando codigo fuente..."
cp "$LAMBDA_DIR/handler.py" "$BUILD_DIR/"

echo "Instalando dependencias..."
pip install -r "$LAMBDA_DIR/requirements.txt" -t "$BUILD_DIR/" --platform manylinux2014_x86_64 --implementation cp --python-version 3.11 --only-binary=:all: --upgrade

echo "Verificando instalacion de psycopg2..."
if [ -d "$BUILD_DIR/psycopg2" ]; then
    echo "psycopg2 instalado correctamente"
else
    echo "ERROR: psycopg2 no se instalo"
    exit 1
fi

echo "Creando archivo ZIP..."
cd "$BUILD_DIR"
zip -r -q "../../$OUTPUT_ZIP" .
cd ../..

ZIP_SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
echo "Lambda empaquetada: $OUTPUT_ZIP ($ZIP_SIZE)"
