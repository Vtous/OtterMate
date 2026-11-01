#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
INSTALL_DIRECTORY="${1:-$HOME/Applications}"
APP_DIR="$INSTALL_DIRECTORY/水獭助手.app"
ARCHIVE="$PROJECT_DIR/dist/OtterMate-macOS-arm64.zip"
if [[ -e "$APP_DIR" ]]; then
  print "应用已存在：$APP_DIR。为保留现有版本，本脚本不会覆盖。"
  exit 1
fi
if [[ ! -f "$ARCHIVE" ]]; then /bin/zsh "$PROJECT_DIR/scripts/build.sh"; fi
(cd "$PROJECT_DIR/dist" && shasum -a 256 -c SHA256SUMS)
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/appinput-install.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
/usr/bin/ditto -x -k "$ARCHIVE" "$STAGING_DIR"
codesign --verify --strict "$STAGING_DIR/水獭助手.app"
mkdir -p "$INSTALL_DIRECTORY"
/usr/bin/ditto --norsrc --noextattr "$STAGING_DIR/水獭助手.app" "$APP_DIR"
codesign --verify --strict "$APP_DIR"
print "已安装：$APP_DIR"
