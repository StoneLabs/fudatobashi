#!/usr/bin/env bash
# Makes the database dumps of a released version, for test/past_db_test.dart.
# Usage: tool/past_db/make_past_db.sh v1.3.0
set -euo pipefail
tag="${1:?usage: make_past_db.sh <tag>}"
repo="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export PATH="${FLUTTER_ROOT:-$HOME/dev/flutter}/bin:$PATH"

git -C "$repo" archive "$tag" | tar -x -C "$work"
cp "$repo"/tool/past_db/past_db_json.dart "$repo"/tool/past_db/make_past_db_test.dart "$work/test/"
tests=(test/make_past_db_test.dart)
if grep -q seedRankedDemoData "$work/lib/state/demo_data.dart"; then
  cp "$repo/tool/past_db/make_past_db_ranked_test.dart" "$work/test/"
  tests+=(test/make_past_db_ranked_test.dart)
fi
cd "$work"
flutter pub get >/dev/null
PAST_DB_TAG="$tag" PAST_DB_OUT="$work/out" flutter test "${tests[@]}"

cp "$work"/out/"$tag"_* "$repo/test/past_db/"
ls -l "$repo"/test/past_db/"$tag"_*
