#!/bin/bash
set -euo pipefail

CONFIG="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Torr"
BUNDLE_DIR="$PROJECT_DIR/build/${APP_NAME}.app"
DMG_PATH="$PROJECT_DIR/build/${APP_NAME}.dmg"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
NOTARY_APPLE_ID="${NOTARY_APPLE_ID:-}"
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-}"
NOTARY_PASSWORD="${NOTARY_PASSWORD:-}"

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

if [ -n "$SIGN_IDENTITY" ]; then
    echo ""
    echo "==> Signing app bundle..."
    codesign --force --deep --options runtime --timestamp \
        --sign "$SIGN_IDENTITY" \
        "$BUNDLE_DIR"

    codesign --verify --deep --strict --verbose=2 "$BUNDLE_DIR"
else
    echo ""
    echo "==> Skipping code signing (SIGN_IDENTITY not set)"
fi

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

    if [ -n "$SIGN_IDENTITY" ]; then
        echo ""
        echo "==> Signing DMG..."
        codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
        codesign --verify --verbose=2 "$DMG_PATH"
    fi

    if [ -n "$NOTARY_KEYCHAIN_PROFILE" ]; then
        echo ""
        echo "==> Notarizing DMG with keychain profile..."
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
            --wait
        xcrun stapler staple "$DMG_PATH"
    elif [ -n "$NOTARY_APPLE_ID" ] && [ -n "$NOTARY_TEAM_ID" ] && [ -n "$NOTARY_PASSWORD" ]; then
        echo ""
        echo "==> Notarizing DMG with Apple ID credentials..."
        xcrun notarytool submit "$DMG_PATH" \
            --apple-id "$NOTARY_APPLE_ID" \
            --team-id "$NOTARY_TEAM_ID" \
            --password "$NOTARY_PASSWORD" \
            --wait
        xcrun stapler staple "$DMG_PATH"
    else
        echo ""
        echo "==> Skipping notarization (notary credentials not set)"
    fi

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
