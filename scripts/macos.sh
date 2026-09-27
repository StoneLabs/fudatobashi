#!/usr/bin/env bash
# Builds the macOS desktop app into dist/macos/. Only works on a Mac with Xcode.
set -e
source "$(dirname "$0")/env.sh"
[ "$(uname)" = "Darwin" ] || { echo "macOS builds need macOS with Xcode." >&2; exit 1; }
flutter build macos --release
rm -rf dist/macos && cp -r build/macos/Build/Products/Release dist/macos
echo "Built dist/macos/"
