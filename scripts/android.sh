#!/usr/bin/env bash
# Builds the Android app into dist/fudatobashi.apk (shareable, installable on any Android phone).
#   ./scripts/android.sh           build only
#   ./scripts/android.sh install   build and install on the phone connected by USB
set -e
source "$(dirname "$0")/env.sh"
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk dist/fudatobashi.apk
echo "Built dist/fudatobashi.apk"
if [ "$1" = "install" ]; then
  adb install -r dist/fudatobashi.apk
  adb shell am start -n dev.fudatobashi.fudatobashi/.MainActivity >/dev/null
fi
