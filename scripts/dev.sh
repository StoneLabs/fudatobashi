#!/usr/bin/env bash
# Runs the app on the connected phone in debug mode with hot reload
# (press r to reload, R to restart, q to quit).
set -e
source "$(dirname "$0")/env.sh"
flutter run
