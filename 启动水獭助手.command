#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
APP_DIR="$HOME/Applications/水獭助手.app"
if [[ ! -d "$APP_DIR" ]]; then
  /bin/zsh "$PROJECT_DIR/scripts/install.sh"
fi
open "$APP_DIR" --args --settings
