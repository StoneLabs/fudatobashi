#!/usr/bin/env bash
# Builds the Windows desktop app into dist/windows/. Only works on Windows
# (run from Git Bash) with Flutter and Visual Studio's C++ tools installed.
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) echo "Windows builds need Windows." >&2; exit 1 ;; esac
flutter build windows --release --build-name="$BUILD_VERSION" --build-number="$BUILD_NUMBER" --dart-define=BUILD_NAME="$BUILD_NAME"
rm -rf dist/windows && cp -r build/windows/x64/runner/Release dist/windows
echo "Built dist/windows/fudatobashi.exe"
