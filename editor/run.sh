#!/usr/bin/env bash
# Builds the editor (release) and runs it. Arguments go to the editor; the
# first one is the skins folder. With none, and no settings file yet, the
# skins folder next to this script is used.
set -euo pipefail
export PATH=$HOME/dev/flutter/bin:$PATH
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"
flutter build linux --release
args=("$@")
settings="$HOME/.config/fudatobashi-skin-editor/settings.json"
if [ ${#args[@]} -eq 0 ] && [ ! -f "$settings" ]; then
  args=("$here/skins")
fi
exec "$here/build/linux/x64/release/bundle/fudatobashi_skin_editor" "${args[@]}"
