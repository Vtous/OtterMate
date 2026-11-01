#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
mkdir -p "$PROJECT_DIR/.build/module-cache"
xcrun swiftc -swift-version 5 -parse-as-library \
  -module-cache-path "$PROJECT_DIR/.build/module-cache" \
  "$PROJECT_DIR/Sources/Core.swift" "$PROJECT_DIR/Tests/CoreTests.swift" \
  -o "$PROJECT_DIR/.build/core-tests"
"$PROJECT_DIR/.build/core-tests"
