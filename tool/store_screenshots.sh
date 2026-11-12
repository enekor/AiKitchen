#!/usr/bin/env sh
# Generates the Play Store screenshots (no emulator needed) into
# screenshots/<vertical|horizontal>/.
# Usage: tool/store_screenshots.sh [vertical] [horizontal]
set -e
cd "$(dirname "$0")/.."

orientations="$*"
[ -z "$orientations" ] && orientations="vertical horizontal"

# The tests open sqlite through FFI, which looks for "libsqlite3.so". Many
# systems only ship the runtime "libsqlite3.so.0" (no -dev package), so point
# the loader at it through a temporary symlink instead of installing anything.
if ! ldconfig -p 2>/dev/null | grep -q 'libsqlite3\.so '; then
  runtime=$(ldconfig -p 2>/dev/null | awk '/libsqlite3\.so\.0 /{print $NF; exit}')
  if [ -n "$runtime" ]; then
    libdir=$(mktemp -d)
    ln -s "$runtime" "$libdir/libsqlite3.so"
    export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    trap 'rm -rf "$libdir"' EXIT
  fi
fi

for orientation in $orientations; do
  echo "==> Generating $orientation screenshots"
  flutter test test/store_screenshots \
    --dart-define=STORE_SCREENSHOTS=true \
    --dart-define=SCREENSHOT_ORIENTATION="$orientation"
done

echo "Done: $(pwd)/screenshots"
