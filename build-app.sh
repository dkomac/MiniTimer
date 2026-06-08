#!/bin/bash
#
# Builds MiniTimer.app — a standalone, double-clickable macOS menu bar app.
#
# Usage:
#   ./build-app.sh            # build into ./MiniTimer.app
#   ./build-app.sh --install  # also copy to /Applications
#
set -euo pipefail

APP_NAME="MiniTimer"
EXECUTABLE="MiniTimerApp"
BUNDLE_ID="io.beyondloops.minitimer"
VERSION="1.0"
MIN_MACOS="13.0"

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/$APP_NAME.app"

echo "==> Building release binary…"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)/$EXECUTABLE"

if [[ ! -f "$BIN_PATH" ]]; then
    echo "error: built binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling $APP_NAME.app…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so the app opens without a "damaged" warning when moved around.
echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || \
    echo "   (codesign skipped — app will still run locally)"

echo "==> Done: $APP_DIR"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> Installing to /Applications…"
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_DIR" "/Applications/$APP_NAME.app"
    echo "==> Installed: /Applications/$APP_NAME.app"
fi
