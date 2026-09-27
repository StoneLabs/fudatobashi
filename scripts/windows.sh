#!/usr/bin/env bash
# Builds the Windows desktop app into dist/windows/. Only works on Windows
# (run from Git Bash) with Flutter and Visual Studio's C++ tools installed.
set -e
source "$(dirname "$0")/env.sh"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) echo "Windows builds need Windows." >&2; exit 1 ;; esac
flutter build windows --release
rm -rf dist/windows && cp -r build/windows/x64/runner/Release dist/windows
echo "Built dist/windows/fudatobashi.exe"
