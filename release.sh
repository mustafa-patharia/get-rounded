#!/bin/bash
# Package the release archives into dist/. Run make_app.sh first on macOS.
set -e
cd "$(dirname "$0")"

VERSION="${1:-1.0}"
OUT="dist"
COMMON=(app.py index.html tailwind.js logo.png requirements.txt README.md LICENSE)

rm -rf "$OUT" && mkdir -p "$OUT"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# --- macOS: self-contained app bundle (Python + deps baked in via PyInstaller)
[ -d GetRounded.app ] || ./make_app.sh
mkdir -p "$STAGE/mac"
cp -R GetRounded.app "$STAGE/mac/"
cp README.md LICENSE "$STAGE/mac/"
(cd "$STAGE/mac" && zip -qr "$OLDPWD/$OUT/GetRounded-$VERSION-macOS.zip" .)

# --- Windows
mkdir -p "$STAGE/win"
cp "${COMMON[@]}" GetRounded.bat "$STAGE/win/"
(cd "$STAGE/win" && zip -qr "$OLDPWD/$OUT/GetRounded-$VERSION-Windows.zip" .)

# --- Linux
mkdir -p "$STAGE/linux/GetRounded"
cp "${COMMON[@]}" GetRounded.sh "$STAGE/linux/GetRounded/"
tar -czf "$OUT/GetRounded-$VERSION-Linux.tar.gz" -C "$STAGE/linux" GetRounded

ls -lh "$OUT"
