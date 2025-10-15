#!/bin/bash

# Script de compilación para Always On Top

set -e

echo "🔨 Compilando Always On Top..."

# Limpiar compilaciones anteriores
rm -rf build

# Crear directorios
mkdir -p build/AlwaysOnTop.app/Contents/MacOS
mkdir -p build/AlwaysOnTop.app/Contents/Resources

# Compilar el ejecutable
swiftc -O \
    -framework Cocoa \
    -framework Foundation \
    -framework UserNotifications \
    AlwaysOnTop/main.swift \
    -o build/AlwaysOnTop.app/Contents/MacOS/AlwaysOnTop

# Copiar Info.plist
cp Info.plist build/AlwaysOnTop.app/Contents/

# Hacer el ejecutable ejecutable
chmod +x build/AlwaysOnTop.app/Contents/MacOS/AlwaysOnTop

echo "✅ Compilación exitosa!"
echo "📦 La aplicación está en: build/AlwaysOnTop.app"
echo ""
echo "Para instalar, ejecuta:"
echo "  cp -r build/AlwaysOnTop.app /Applications/"
echo ""
echo "Para ejecutar directamente:"
echo "  open build/AlwaysOnTop.app"
