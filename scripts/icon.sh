#!/usr/bin/env bash
# Rasterises assets/icon/*.svg to PNGs and regenerates the Android/iOS launcher icons
# and Android's notification icon.
#   ./scripts/icon.sh
set -e
source "$(dirname "$0")/env.sh"
for name in tobi_background tobi_foreground tobi_monochrome tobi_full; do
  rsvg-convert -w 1024 -h 1024 "assets/icon/$name.svg" -o "assets/icon/$name.png"
done
dart run flutter_launcher_icons
# Android's small notification icon (the training reminders): 24 dp.
for density in mdpi:24 hdpi:36 xhdpi:48 xxhdpi:72 xxxhdpi:96; do
  rsvg-convert -w "${density#*:}" -h "${density#*:}" assets/icon/tobi_notification.svg \
    -o "android/app/src/main/res/drawable-${density%%:*}/ic_notification.png"
done
echo "Launcher and notification icons updated."
