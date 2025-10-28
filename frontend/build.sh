#!/bin/bash
set -e

echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

echo "Installing Flutter..."

# Download and install Flutter
if [ ! -d "$HOME/flutter" ]; then
  cd $HOME
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  cd -
fi

export PATH="$HOME/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web..."

# Check if we're already in frontend directory or need to navigate
if [ -d "mercatico_app" ]; then
  echo "Found mercatico_app in current directory"
  cd mercatico_app
elif [ -d "frontend/mercatico_app" ]; then
  echo "Found mercatico_app in frontend/"
  cd frontend/mercatico_app
else
  echo "ERROR: Cannot find mercatico_app directory"
  echo "Current directory structure:"
  find . -maxdepth 2 -type d
  exit 1
fi

echo "Running flutter pub get..."
flutter pub get

echo "Running flutter build web..."
flutter build web --release

echo "Build complete!"
echo "Build output directory:"
ls -la build/web/
