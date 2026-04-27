#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="SwiftEdit"
SCHEME="SwiftEdit"
CONFIGURATION="${1:-Debug}"
BUILD_DIR="$SCRIPT_DIR/build"

echo "==> Building $PROJECT_NAME ($CONFIGURATION)..."

if [[ "${CLEAN:-0}" == "1" ]]; then
    echo "==> Cleaning..."
    rm -rf "$BUILD_DIR"
fi

xcodebuild \
    -project "$SCRIPT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    SYMROOT="$BUILD_DIR" \
    build

APP_PATH="$BUILD_DIR/$CONFIGURATION/$PROJECT_NAME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "==> Build succeeded!"
    echo "    $APP_PATH"
    echo ""
    echo "Run with:"
    echo "    open '$APP_PATH'"
else
    echo "==> Build failed: $APP_PATH not found"
    exit 1
fi
