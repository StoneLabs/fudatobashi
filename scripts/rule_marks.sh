#!/usr/bin/env bash
# Re-renders the little marks in 暗記練's and 定位置's rules (tool/rule_marks/)
# into assets/graphics/sidetrips/rules/ as lossless WebP, at 4 pixels per dp.
# Run it again after changing the icons, the palette or the mark's size.
#   ./scripts/rule_marks.sh
set -e
source "$(dirname "$0")/env.sh"
rm -rf build/rule_marks
flutter test tool/rule_marks/render_marks_test.dart
mkdir -p assets/graphics/sidetrips/rules
for png in build/rule_marks/*.png; do
  magick "$png" -define webp:lossless=true "assets/graphics/sidetrips/rules/$(basename "$png" .png).webp"
done
rm -rf build/rule_marks
ls assets/graphics/sidetrips/rules
