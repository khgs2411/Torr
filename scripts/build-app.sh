#!/bin/bash
set -euo pipefail

CONFIG="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Torr"
BUNDLE_DIR="$PROJECT_DIR/build/${APP_NAME}.app"
DMG_PATH="$PROJECT_DIR/build/${APP_NAME}.dmg"

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

# Copy app icon
if [ -f "$PROJECT_DIR/assets/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/assets/AppIcon.icns" "$BUNDLE_DIR/Contents/Resources/"
fi

echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

echo "==> App bundle created:"
echo "    $BUNDLE_DIR"
echo "    Size: $(du -sh "$BUNDLE_DIR" | cut -f1)"

# Create DMG for distribution
if [ "$CONFIG" = "release" ]; then
    echo ""
    echo "==> Creating DMG..."

    rm -f "$DMG_PATH"

    # Create a temporary directory for DMG contents
    DMG_STAGING="$PROJECT_DIR/build/dmg-staging"
    rm -rf "$DMG_STAGING"
    mkdir -p "$DMG_STAGING"

    cp -R "$BUNDLE_DIR" "$DMG_STAGING/"
    ln -s /Applications "$DMG_STAGING/Applications"

    hdiutil create -volname "Torr" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        "$DMG_PATH" > /dev/null

    rm -rf "$DMG_STAGING"

    # Clean up — only keep the DMG
    rm -rf "$BUNDLE_DIR"

    echo "==> DMG created:"
    echo "    $DMG_PATH"
    echo "    Size: $(du -sh "$DMG_PATH" | cut -f1)"
fi

echo ""
echo "==> Done!"
if [ "$CONFIG" = "release" ]; then
    echo "    Share:   $DMG_PATH"
else
    echo "    Run:     open $BUNDLE_DIR"
fi
