#!/usr/bin/env bash
# Builds the web version into dist/web/ (serve that folder with any static web server).
#   ./scripts/web.sh         build only
#   ./scripts/web.sh serve   build and open it at http://localhost:8000
set -e
source "$(dirname "$0")/env.sh"
flutter build web --release
rm -rf dist/web && cp -r build/web dist/web
echo "Built dist/web/"
if [ "$1" = "serve" ]; then
  (sleep 1 && firefox http://localhost:8000 >/dev/null 2>&1 &)
  python3 -m http.server 8000 --directory dist/web
fi
