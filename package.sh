#!/bin/bash

# Script para empaquetar AltoPin para release

set -e

VERSION="1.2.0"
APP_NAME="AlwaysOnTop.app"
BUILD_DIR="build"
RELEASE_DIR="release"
ZIP_NAME="AlwaysOnTop.app.zip"

echo "📦 Empaquetando AltoPin v${VERSION}..."

# Limpiar y crear directorio de release
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Verificar que la app existe
if [ ! -d "$BUILD_DIR/$APP_NAME" ]; then
    echo "❌ Error: $BUILD_DIR/$APP_NAME no existe. Ejecuta build.sh primero."
    exit 1
fi

echo "✅ App encontrada en $BUILD_DIR/$APP_NAME"

# Copiar app al directorio de release
echo "📋 Copiando app..."
cp -r "$BUILD_DIR/$APP_NAME" "$RELEASE_DIR/"

# Crear ZIP
echo "🗜️  Creando ZIP..."
cd "$RELEASE_DIR"
zip -r -q "$ZIP_NAME" "$APP_NAME"
cd ..

# Calcular SHA256
echo "🔐 Calculando SHA256..."
SHA256=$(shasum -a 256 "$RELEASE_DIR/$ZIP_NAME" | awk '{print $1}')

echo ""
echo "✅ Empaquetado completado!"
echo ""
echo "📦 Archivo: $RELEASE_DIR/$ZIP_NAME"
echo "🔐 SHA256: $SHA256"
echo ""
echo "📝 Próximos pasos:"
echo "1. Crear release en GitHub: https://github.com/jagoff/altopin/releases/new"
echo "2. Tag: v${VERSION}"
echo "3. Subir: $RELEASE_DIR/$ZIP_NAME"
echo "4. Actualizar Casks/altopin.rb con el SHA256:"
echo "   sha256 \"$SHA256\""
echo ""
