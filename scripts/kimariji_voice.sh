#!/usr/bin/env bash
# Regenerates assets/voice/kimariji/*.m4a from assets/data/poems.json (see
# scripts/kimariji_voice.py). Creates a throwaway venv on first run.
#   ./scripts/kimariji_voice.sh
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."

VENV=.scratchpad/.venv-voice
if [ ! -d "$VENV" ]; then
  uv venv --python 3.12 "$VENV"
fi
uv pip install --python "$VENV/bin/python" pyopenjtalk numpy

"$VENV/bin/python" scripts/kimariji_voice.py
