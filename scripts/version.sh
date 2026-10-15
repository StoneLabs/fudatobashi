# Works out the app's version from git and pubspec.yaml. The build scripts source
# it and the Build workflow runs it, so local and CI builds get the same names.
# Run it on its own to print the names.
#   BUILD_NUMBER  number of commits so far, e.g. 286 (the Android versionCode)
#   BUILD_NAME    the pubspec version (1.4.0) on a commit tagged v*, otherwise
#                 1.4.0-dev.286.abc1234 (commit count and short hash); ".dirty"
#                 is added when files are uncommitted (1.4.0-dirty on a tag)
# iOS, macOS and Windows need a plain number, so they only use BUILD_NUMBER.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_NUMBER="$(git -C "$root" rev-list --count HEAD)"
BUILD_NAME="$(sed -n 's/^version: *\([^+[:space:]]*\).*/\1/p' "$root/pubspec.yaml")"
suffix=""
if ! git -C "$root" describe --tags --exact-match --match 'v*' >/dev/null 2>&1; then
  suffix="dev.$BUILD_NUMBER.$(git -C "$root" rev-parse --short=7 HEAD)"
fi
if ! git -C "$root" diff --quiet HEAD; then
  suffix="${suffix:+$suffix.}dirty"
fi
if [ -n "$suffix" ]; then
  BUILD_NAME="$BUILD_NAME-$suffix"
fi
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "BUILD_NAME=$BUILD_NAME"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
fi
