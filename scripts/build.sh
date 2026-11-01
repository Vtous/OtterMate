#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
BUILD_DIR="$PROJECT_DIR/.build"
OUTPUT_ARCHIVE="$PROJECT_DIR/dist/OtterMate-macOS-arm64.zip"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/appinput-build.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
APP_DIR="$STAGING_DIR/水獭助手.app"
mkdir -p "$BUILD_DIR/module-cache" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$PROJECT_DIR/dist"
xcrun swiftc -swift-version 5 -O -target arm64-apple-macos14.0 \
  -module-cache-path "$BUILD_DIR/module-cache" \
  -framework AppKit -framework SwiftUI -framework Carbon -framework ServiceManagement \
  "$PROJECT_DIR/Sources/Core.swift" \
  "$PROJECT_DIR/Sources/InputSources.swift" \
  "$PROJECT_DIR/Sources/AppModel.swift" \
  "$PROJECT_DIR/Sources/SettingsView.swift" \
  "$PROJECT_DIR/Sources/main.swift" \
  -o "$APP_DIR/Contents/MacOS/OtterMate"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]]; then
  cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/OtterMateStandard.icns"
fi
cp "$PROJECT_DIR/Resources/AppIconPreview.png" "$APP_DIR/Contents/Resources/AppIconPreview.png"
cp "$PROJECT_DIR/Resources/MenuBarIcon.png" "$APP_DIR/Contents/Resources/MenuBarIcon.png"
/usr/bin/xattr -cr "$APP_DIR"
codesign --force --sign - --options runtime "$APP_DIR"
codesign --verify --strict "$APP_DIR"
/usr/bin/ditto -c -k --norsrc --noextattr --keepParent "$APP_DIR" "$OUTPUT_ARCHIVE"
mkdir -p "$STAGING_DIR/verify"
/usr/bin/ditto -x -k "$OUTPUT_ARCHIVE" "$STAGING_DIR/verify"
codesign --verify --strict "$STAGING_DIR/verify/水獭助手.app"
(cd "$PROJECT_DIR/dist" && shasum -a 256 "OtterMate-macOS-arm64.zip" > SHA256SUMS)
print "已构建并验证：$OUTPUT_ARCHIVE"
