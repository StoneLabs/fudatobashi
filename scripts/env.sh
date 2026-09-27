# Shared setup for the build scripts: finds Flutter, the Android SDK and Java.
# Override any of these by exporting them before running a script.
export FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/dev/flutter}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/platform-tools:$PATH"

if ! command -v flutter >/dev/null; then
  echo "Flutter not found at $FLUTTER_ROOT (set FLUTTER_ROOT)." >&2
  exit 1
fi
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p dist
