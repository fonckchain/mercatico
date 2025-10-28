#!/bin/bash
set -e

echo "Installing Flutter..."

# Download and install Flutter
if [ ! -d "$HOME/flutter" ]; then
  cd $HOME
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$HOME/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web..."
cd mercatico_app
flutter pub get
flutter build web --release

echo "Build complete!"
