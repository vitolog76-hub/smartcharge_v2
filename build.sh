#!/bin/bash
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Fix per l'errore root
export FLUTTER_ROOT="$HOME/flutter"

# Clean build
echo "🧹 Cleaning previous builds..."
rm -rf .dart_tool build

# Install Flutter (se non esiste)
echo "📦 Installing Flutter..."
if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone --branch stable https://github.com/flutter/flutter.git $FLUTTER_ROOT
fi

# Aggiungi al PATH
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Ignora l'avviso root
flutter config --no-analytics --disable-telemetry

flutter config --enable-web
echo "📌 Flutter version: $(flutter --version | head -1)"

# Get dependencies
echo "📚 Getting dependencies..."
flutter pub get

# Build web
echo "🌐 Building web..."
flutter build web --release --no-wasm-dry-run

# Verify
if [ -d "build/web" ]; then
  echo "✅ Build successful! Output in build/web"
  ls -la build/web | head -10
else
  echo "❌ Build failed"
  exit 1
fi

echo "🎉 Build completata con successo!"