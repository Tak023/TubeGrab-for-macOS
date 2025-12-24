#!/bin/bash

# TubeGrab for macOS - Build Script
# Builds a native macOS app bundle using Swift Package Manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="TubeGrab"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building TubeGrab for macOS..."
echo ""

# Build the executable
echo "[1/4] Compiling Swift code..."
swift build -c release

# Create app bundle structure
echo "[2/4] Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Create Info.plist
echo "[3/4] Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TubeGrab</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.tubegrab.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>TubeGrab</string>
    <key>CFBundleDisplayName</key>
    <string>TubeGrab</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.video</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create icns file from PNG if available
echo "[4/4] Setting up resources..."
if [ -f "../tubegrab.png" ]; then
    # Create iconset
    ICONSET_DIR="$RESOURCES_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"

    # Generate icon sizes using sips
    sips -z 16 16 "../tubegrab.png" --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || true
    sips -z 32 32 "../tubegrab.png" --out "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null || true
    sips -z 32 32 "../tubegrab.png" --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || true
    sips -z 64 64 "../tubegrab.png" --out "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null || true
    sips -z 128 128 "../tubegrab.png" --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || true
    sips -z 256 256 "../tubegrab.png" --out "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null || true
    sips -z 256 256 "../tubegrab.png" --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || true
    cp "../tubegrab.png" "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null || true
    cp "../tubegrab.png" "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || true
    cp "../tubegrab.png" "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null || true

    # Convert to icns
    if command -v iconutil &> /dev/null; then
        iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
        rm -rf "$ICONSET_DIR"
    fi
fi

echo ""
echo "Build complete!"
echo ""
echo "App bundle created: $SCRIPT_DIR/$APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To install to /Applications:"
echo "  cp -r $APP_BUNDLE /Applications/"
echo ""

# Optionally open the app
if [ "$1" == "--run" ]; then
    echo "Launching TubeGrab..."
    open "$APP_BUNDLE"
fi
