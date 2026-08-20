#!/bin/bash
# Build a fully self-contained GetRounded.app (Python + deps bundled via
# PyInstaller). No system Python needed on the user's machine, and the
# .app is safe to drag anywhere alone — no sibling files required.
set -e
cd "$(dirname "$0")"

APP="GetRounded.app"
VENV=".buildenv"

# --- icon
rm -rf logo.iconset icon.icns
mkdir -p logo.iconset
for size in 16 32 128 256 512; do
  sips -z $size $size logo.png --out "logo.iconset/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) logo.png \
       --out "logo.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns logo.iconset -o icon.icns
rm -rf logo.iconset

# --- build env with pyinstaller + app deps
[ -d "$VENV" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install -q -r requirements.txt pyinstaller

# --- bundle
rm -rf "$APP" build dist GetRounded.spec
"$VENV/bin/pyinstaller" --windowed --name GetRounded \
  --icon icon.icns \
  --add-data "index.html:." \
  --add-data "tailwind.js:." \
  --add-data "logo.png:." \
  --osx-bundle-identifier com.getrounded.app \
  app.py >/dev/null

mv dist/GetRounded.app .
rm -rf build dist GetRounded.spec icon.icns

echo "Built $APP — fully self-contained, drag it anywhere (e.g. /Applications)."
