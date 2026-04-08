#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build/release"
APP_DIR="$SCRIPT_DIR/.build/ClaudeBuddy.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building ClaudeBuddy (release)..."
cd "$SCRIPT_DIR"
swift build -c release 2>&1

echo "==> Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BUILD_DIR/ClaudeBuddy" "$MACOS/ClaudeBuddy"
cp "$SCRIPT_DIR/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns" 2>/dev/null || true

# Copy 3D models if they exist
if [ -d "$SCRIPT_DIR/Resources/Models" ]; then
    mkdir -p "$RESOURCES/Models"
    cp "$SCRIPT_DIR/Resources/Models/"*.usdz "$RESOURCES/Models/" 2>/dev/null || true
    # Copy rigged models with animations
    if [ -d "$SCRIPT_DIR/Resources/Models/rigged" ]; then
        mkdir -p "$RESOURCES/Models/rigged"
        cp "$SCRIPT_DIR/Resources/Models/rigged/"*.usdz "$RESOURCES/Models/rigged/" 2>/dev/null || true
        echo "    Copied 3D models + rigged animations to bundle"
    else
        echo "    Copied 3D models to bundle"
    fi
fi

# Sign ad-hoc for local use
codesign --force --sign - "$APP_DIR" 2>/dev/null || true

echo "==> Done! App bundle: $APP_DIR"
echo "    Run with: open $APP_DIR"
