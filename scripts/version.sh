# Works out the app's version from git and pubspec.yaml. The build scripts source
# it and the Build workflow runs it, so local and CI builds get the same names.
# Run it on its own to print the names.
#   BUILD_NUMBER   number of commits so far, e.g. 286 (the Android versionCode)
#   BUILD_VERSION  plain X.Y.Z for platforms that need one (iOS, macOS, Windows):
#                  the pubspec version on a commit tagged v*, otherwise the pubspec
#                  version with the patch number plus 1 (2.1.0 gives 2.1.1)
#   BUILD_NAME     the pubspec version (2.1.0) on a tagged commit, otherwise
#                  <BUILD_VERSION>-indev.<commit count>.<short hash>, e.g.
#                  2.1.1-indev.286.abc1234; ".dirty" is added when files are
#                  uncommitted (2.1.0-dirty on a tag)
# So a dev build after a release is named after the NEXT patch version and never
# collides with the released one in the stores. pubspec.yaml keeps the last
# released version. At release, set pubspec to the real next version (patch, minor
# or major), tag it vX.Y.Z, and never bump pubspec after a release.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_NUMBER="$(git -C "$root" rev-list --count HEAD)"
BUILD_VERSION="$(sed -n 's/^version: *\([^+[:space:]]*\).*/\1/p' "$root/pubspec.yaml")"
BUILD_NAME="$BUILD_VERSION"
suffix=""
if ! git -C "$root" describe --tags --exact-match --match 'v*' >/dev/null 2>&1; then
  BUILD_VERSION="${BUILD_VERSION%.*}.$(( ${BUILD_VERSION##*.} + 1 ))"
  BUILD_NAME="$BUILD_VERSION"
  suffix="indev.$BUILD_NUMBER.$(git -C "$root" rev-parse --short=7 HEAD)"
fi
if ! git -C "$root" diff --quiet HEAD; then
  suffix="${suffix:+$suffix.}dirty"
fi
if [ -n "$suffix" ]; then
  BUILD_NAME="$BUILD_NAME-$suffix"
fi
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "BUILD_VERSION=$BUILD_VERSION"
  echo "BUILD_NAME=$BUILD_NAME"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
fi
