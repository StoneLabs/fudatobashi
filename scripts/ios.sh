#!/usr/bin/env bash
# Builds the iPhone app. Only works on a Mac with Xcode installed and an Apple
# developer account selected in Xcode (open ios/Runner.xcworkspace once to set the team).
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/version.sh"
[ "$(uname)" = "Darwin" ] || { echo "iOS builds need macOS with Xcode." >&2; exit 1; }
flutter build ipa --release --build-number="$BUILD_NUMBER"
echo "Built build/ios/ipa/ (upload with Xcode or Transporter, e.g. to TestFlight)"
