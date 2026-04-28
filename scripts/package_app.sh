#!/usr/bin/env bash
set -euo pipefail

# Ships to App Store Connect app "Audio Silence Remover" (macOS only).
# Bundle ID must match ASC: com.felipebasurto.audiosilenceremover
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/Silence Remover.app"
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/SoundRemover" "$MACOS_DIR/SoundRemover"
cp "$BUILD_DIR/SoundRemover_SoundRemoverUI.bundle/ffmpeg" "$RESOURCES_DIR/ffmpeg"
cp "$ROOT_DIR/Sources/SoundRemover/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp -R "$ROOT_DIR/Sources/SoundRemover/Resources/en.lproj" "$RESOURCES_DIR/en.lproj"
cp -R "$ROOT_DIR/Sources/SoundRemover/Resources/es.lproj" "$RESOURCES_DIR/es.lproj"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SoundRemover</string>
    <key>CFBundleIdentifier</key>
    <string>com.felipebasurto.audiosilenceremover</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Silence Remover</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/SoundRemover"
chmod +x "$RESOURCES_DIR/ffmpeg"
codesign --force --deep --sign - "$APP_PATH"
echo "$APP_PATH"
