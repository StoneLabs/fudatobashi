#!/usr/bin/env bash
# Runs the app on the connected phone in debug mode with hot reload
# (press r to reload, R to restart, q to quit). The version name and build
# number come from scripts/version.sh, as for the other builds.
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"
flutter run --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
