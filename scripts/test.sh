#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/farlook-clang-cache"
swiftc SessionTimer.swift TimerTests.swift -o build/timer-tests
build/timer-tests
