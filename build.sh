#!/bin/bash
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Clean build
echo "🧹 Cleaning previous builds..."
rm -rf .dart_tool build

# Install Flutter
echo "📦 Installing Flutter..."
FLUTTER_SDK_PATH="$HOME/flutter"
if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  git clone --branch stable https://github.com/flutter/flutter.git $FLUTTER_SDK_PATH
fi
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

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