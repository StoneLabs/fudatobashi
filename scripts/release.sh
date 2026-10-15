#!/usr/bin/env bash
# Builds a signed Android release: an .aab to upload to Google Play (e.g. a testing
# track) and an .apk for sideloading, both in dist/. First time:
#   cp .secrets_example .secrets   then edit the paths in .secrets
#   ./scripts/release.sh
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"

[ -f .secrets ] || { echo "Missing .secrets. Run: cp .secrets_example .secrets, then edit it." >&2; exit 1; }
source .secrets
for var in KEYSTORE_FILE KEY_PROPERTIES; do
  file="${!var}"
  [ -f "$file" ] || { echo "$var in .secrets is not a file: '$file'" >&2; exit 1; }
done
for key in storePassword keyPassword keyAlias; do
  grep -q "^$key=" "$KEY_PROPERTIES" || { echo "$KEY_PROPERTIES has no $key= line." >&2; exit 1; }
done

# The Gradle build signs with android/key.properties when that file exists.
# It is built from your properties file and removed again when the script ends.
[ ! -e android/key.properties ] || { echo "android/key.properties already exists. Move it away first." >&2; exit 1; }
trap 'rm -f android/key.properties' EXIT
(umask 077; { grep -v '^storeFile=' "$KEY_PROPERTIES"; echo "storeFile=$(realpath "$KEYSTORE_FILE")"; } > android/key.properties)

flutter build appbundle --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
flutter build apk --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
cp build/app/outputs/bundle/release/app-release.aab "dist/fudatobashi-$BUILD_NAME.aab"
cp build/app/outputs/flutter-apk/app-release.apk "dist/fudatobashi-$BUILD_NAME.apk"
echo "Built signed dist/fudatobashi-$BUILD_NAME.aab (upload this to Google Play)"
echo "Built signed dist/fudatobashi-$BUILD_NAME.apk (for sideloading)"
