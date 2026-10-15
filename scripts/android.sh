#!/usr/bin/env bash
# Builds the Android app into dist/fudatobashi.apk (shareable, installable on any Android phone).
#   ./scripts/android.sh           build only
#   ./scripts/android.sh install   build and install on the phone connected by USB
# The version name and build number come from scripts/version.sh.
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"
flutter build apk --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
cp build/app/outputs/flutter-apk/app-release.apk dist/fudatobashi.apk
echo "Built dist/fudatobashi.apk ($BUILD_NAME, build $BUILD_NUMBER)"
if [ "$1" = "install" ]; then
  adb install -r dist/fudatobashi.apk
  adb shell am start -n com.sobadev.fudatobashi/.MainActivity >/dev/null
fi
