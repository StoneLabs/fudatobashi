#!/usr/bin/env bash
# Regenerates assets/data/poems.json from StoneLabs' hyakuninissyu-csv on GitHub.
set -e
source "$(dirname "$0")/env.sh"
dart run tool/build_poems.dart
