#!/usr/bin/env bash
# Cuts Yuji Syuku down to the start card's brush lettering (the 序歌 and its
# greeting), so the app bundles a few dozen glyphs instead of the whole font.
# Rerun after changing that lettering (`lib/data/joka.dart`). Needs fonttools
# (`pip install fonttools`).
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
TEXT='難波津に咲くやこの花冬ごもり今を春べと序歌よろしくお願いします'
pyftsubset assets/fonts/YujiSyuku-Regular.ttf --text="$TEXT" --layout-features='*' --no-hinting \
  --output-file=assets/fonts/YujiSyuku-Joka.ttf
