#!/usr/bin/env bash
# Regenerates assets/voice/kimariji/*.m4a with Gemini TTS via OpenRouter (see
# scripts/kimariji_voice.py). Pass poem ids to regenerate only those clips, or
# --check to only re-check the clips' lengths.
# Needs ffmpeg, uv and an OpenRouter API key, either in OPENROUTER_API_KEY or
# in ~/.config/fudatobashi/openrouter.key.
#   ./scripts/kimariji_voice.sh [--check] [ids...]
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."

KEY_FILE="$HOME/.config/fudatobashi/openrouter.key"
if [ -z "$OPENROUTER_API_KEY" ] && [ -r "$KEY_FILE" ]; then
  OPENROUTER_API_KEY="$(< "$KEY_FILE")"
  export OPENROUTER_API_KEY
fi

VENV=.scratchpad/.venv-voice
if [ ! -d "$VENV" ]; then
  uv venv --python 3.12 "$VENV"
fi
uv pip install --quiet --python "$VENV/bin/python" numpy

"$VENV/bin/python" scripts/kimariji_voice.py "$@"
