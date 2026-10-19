#!/bin/sh
# Rebuilds every C1 texture: placed sheets, previews, Brocade strips, mock references.
cd "$(dirname "$0")" || exit 1
python3 sheets_geo.py && python3 sheet_washi.py && python3 sheet_petals.py && python3 previews.py \
  && python3 strips_nishiki.py && ./render_refs.sh
