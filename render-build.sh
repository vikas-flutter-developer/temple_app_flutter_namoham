#!/usr/bin/env bash
# exit on error
set -e

echo "Starting build process..."

# Install Flutter if it's not present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Create a dummy .env if it doesn't exist to prevent runtime errors
if [ ! -f ".env" ]; then
  echo "Creating dummy .env..."
  touch .env
fi

export PATH="$PATH:`pwd`/flutter/bin"

# Pre-download artifacts
echo "Running flutter doctor..."
flutter doctor

# Enable web
echo "Enabling web..."
flutter config --enable-web

# Build
echo "Building web release..."
flutter build web --release

echo "Build complete!"
