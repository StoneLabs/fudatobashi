#!/usr/bin/env bash
# Re-renders the card kana images (assets/glyphs/) from a font file.
#   ./scripts/glyphs.sh ~/Temporary/cb1/SeiKaishoCB1.otf
# The font file itself is never copied into the project.
set -e
FONT_FILE="$(realpath "${1:?usage: ./scripts/glyphs.sh /path/to/font.otf}")"
source "$(dirname "$0")/env.sh"
FONT="$FONT_FILE" flutter test tool/render_glyphs_test.dart
