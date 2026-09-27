#!/usr/bin/env bash
# Checks the code: static analysis plus all tests.
set -e
source "$(dirname "$0")/env.sh"
flutter analyze
flutter test
