#!/usr/bin/env bash
# exit on error
set -o所在地 errexit

# Install Flutter if it's not present
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

# Pre-download artifacts
flutter doctor

# Enable web
flutter config --enable-web

# Build
flutter build web --release
