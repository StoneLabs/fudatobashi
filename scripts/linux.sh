#!/usr/bin/env bash
# Builds the Linux desktop app into dist/linux/ (run dist/linux/fudatobashi).
#   ./scripts/linux.sh       build only
#   ./scripts/linux.sh run   build and start it
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"
flutter build linux --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
rm -rf dist/linux && cp -r build/linux/x64/release/bundle dist/linux
echo "Built dist/linux/fudatobashi"
[ "$1" = "run" ] && ./dist/linux/fudatobashi
exit 0
