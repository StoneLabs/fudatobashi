# Works out the app's version from git and pubspec.yaml. The build scripts source
# it and the Build workflow runs it, so local and CI builds get the same names.
# Run it on its own to print the names.
#   BUILD_NUMBER  number of commits so far, e.g. 286 (the Android versionCode)
#   BUILD_NAME    the pubspec version (1.4.0) on a commit tagged v*, otherwise
#                 1.4.0-beta.286; "-dirty" is added when files are uncommitted
# iOS, macOS and Windows need a plain number, so they only use BUILD_NUMBER.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_NUMBER="$(git -C "$root" rev-list --count HEAD)"
BUILD_NAME="$(sed -n 's/^version: *\([^+[:space:]]*\).*/\1/p' "$root/pubspec.yaml")"
if ! git -C "$root" describe --tags --exact-match --match 'v*' >/dev/null 2>&1; then
  BUILD_NAME="$BUILD_NAME-beta.$BUILD_NUMBER"
fi
if ! git -C "$root" diff --quiet HEAD; then
  BUILD_NAME="$BUILD_NAME-dirty"
fi
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "BUILD_NAME=$BUILD_NAME"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
fi
