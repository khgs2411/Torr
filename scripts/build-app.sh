#!/bin/bash
set -euo pipefail

CONFIG="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Torr"
BUNDLE_DIR="$PROJECT_DIR/build/${APP_NAME}.app"

echo "==> Building Torr ($CONFIG)..."

cd "$PROJECT_DIR"

if [ "$CONFIG" = "release" ]; then
    swift build -c release
    EXEC_PATH=".build/release/${APP_NAME}"
else
    swift build
    EXEC_PATH=".build/debug/${APP_NAME}"
fi

if [ ! -f "$EXEC_PATH" ]; then
    echo "ERROR: Executable not found at $EXEC_PATH"
    exit 1
fi

echo "==> Creating app bundle at $BUNDLE_DIR..."

rm -rf "$BUNDLE_DIR"

mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$EXEC_PATH" "$BUNDLE_DIR/Contents/MacOS/${APP_NAME}"
cp "$PROJECT_DIR/Sources/Torr/Resources/Info.plist" "$BUNDLE_DIR/Contents/"

echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

echo "==> Done! App bundle created at:"
echo "    $BUNDLE_DIR"
echo ""
echo "    To run:  open $BUNDLE_DIR"
echo "    Size:    $(du -sh "$BUNDLE_DIR" | cut -f1)"
