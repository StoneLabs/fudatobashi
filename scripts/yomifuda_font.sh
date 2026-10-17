#!/usr/bin/env bash
# Cuts Yuji Syuku down to the characters the reading cards print (every
# poem's yomifudaColumns in assets/data/poems.json, listed in
# tool/yomifuda_font_chars.txt), so the app bundles a few hundred glyphs
# instead of the whole font. Rerun after regenerating the poems
# (scripts/data.sh). Needs fonttools (`pip install fonttools`).
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 -I - assets/data/poems.json tool/yomifuda_font_chars.txt <<'PY'
import json, re, sys
poems = json.load(open(sys.argv[1], encoding='utf-8'))
text = ''.join(c for p in poems for c in p['yomifudaColumns'])
chars = sorted(set(re.sub(r'[\[\]|ーｰ]', '', text)))
open(sys.argv[2], 'w', encoding='utf-8').write(''.join(chars) + '\n')
PY
pyftsubset assets/fonts/YujiSyuku-Regular.ttf --text-file=tool/yomifuda_font_chars.txt --layout-features='*' \
  --no-hinting --output-file=assets/fonts/YujiSyuku-Yomifuda.ttf
