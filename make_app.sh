#!/bin/bash
# Build GetRounded.app so macOS shows the real icon in the Dock and Finder.
# Uses only built-in tools (sips, iconutil). Re-run after changing logo.png.
set -e
cd "$(dirname "$0")"

APP="GetRounded.app"
rm -rf "$APP" logo.iconset
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" logo.iconset

for size in 16 32 128 256 512; do
  sips -z $size $size logo.png --out "logo.iconset/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) logo.png \
       --out "logo.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns logo.iconset -o "$APP/Contents/Resources/logo.icns"
rm -rf logo.iconset

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>GetRounded</string>
  <key>CFBundleDisplayName</key><string>GetRounded</string>
  <key>CFBundleIdentifier</key><string>com.getrounded.app</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleExecutable</key><string>GetRounded</string>
  <key>CFBundleIconFile</key><string>logo.icns</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

cat > "$APP/Contents/MacOS/GetRounded" <<'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/../../.."
[ -d .venv ] || { python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt; }
exec .venv/bin/python app.py
LAUNCH
chmod +x "$APP/Contents/MacOS/GetRounded"

echo "Built $APP — drag it to your Applications folder or Dock."
