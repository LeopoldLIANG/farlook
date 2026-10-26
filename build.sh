#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
target="${1:-build/远眺一下.app}"
mkdir -p "$target/Contents/MacOS" "$target/Contents/Resources"
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/farlook-clang-cache"
swiftc -O -target arm64-apple-macosx13.0 SessionTimer.swift main.swift -o "$target/Contents/MacOS/FarLook" -framework AppKit -framework CoreGraphics
cp Info.plist "$target/Contents/Info.plist"
zsh scripts/make-icons.sh
cp assets/AppIcon.icns "$target/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$target"
echo "Built: $target"
