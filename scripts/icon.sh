#!/usr/bin/env bash
# Rasterises assets/icon/*.svg to PNGs and regenerates the Android/iOS launcher icons.
#   ./scripts/icon.sh
set -e
source "$(dirname "$0")/env.sh"
for name in tobi_background tobi_foreground tobi_monochrome tobi_full; do
  rsvg-convert -w 1024 -h 1024 "assets/icon/$name.svg" -o "assets/icon/$name.png"
done
dart run flutter_launcher_icons
echo "Launcher icons updated."
