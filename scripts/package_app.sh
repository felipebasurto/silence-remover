#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/AudioSilenceRemover.xcodeproj"
SCHEME="AudioSilenceRemover"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
ARCHIVE_PATH="$DERIVED_DATA_PATH/Archives/Audio Silence Remover.xcarchive"
ARCHIVE_APP_PATH="$ARCHIVE_PATH/Products/Applications/Audio Silence Remover.app"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/Audio Silence Remover.app"

xcodebuild \
  archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH"

rm -rf "$APP_PATH"
mkdir -p "$DIST_DIR"
cp -R "$ARCHIVE_APP_PATH" "$APP_PATH"

"$ROOT_DIR/scripts/ffmpeg_bundle.py" verify "$APP_PATH"
codesign \
  --force \
  --deep \
  --sign - \
  --timestamp=none \
  --options runtime \
  --entitlements "$ROOT_DIR/AudioSilenceRemover/AudioSilenceRemover.entitlements" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "$APP_PATH"
