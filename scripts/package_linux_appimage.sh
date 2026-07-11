#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-v0.8}"
OUT_DIR="${OUT_DIR:-${ROOT}/dist}"
APPIMAGETOOL="${APPIMAGETOOL:-appimagetool}"

VERSION="$VERSION" OUT_DIR="$OUT_DIR" FS_UAE_BUNDLE_BIN="${FS_UAE_BUNDLE_BIN:-}" "$ROOT/scripts/package_linux_x64.sh"

PKG="Enemy-Tempest-Reborn-${VERSION}-linux-x64"
STAGE="${OUT_DIR}/${PKG}"
APPDIR="${OUT_DIR}/Enemy-Tempest-Reborn.AppDir"
APPIMAGE="${OUT_DIR}/Enemy-Tempest-Reborn-${VERSION}-linux-x64.AppImage"
SUM="${APPIMAGE}.sha256"

if [ ! -d "$STAGE" ]; then
  echo "Linux package stage not found: $STAGE" >&2
  exit 2
fi

rm -rf "$APPDIR" "$APPIMAGE" "$SUM"
mkdir -p "$APPDIR/usr/share/enemy-tempest-reborn" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

rsync -a "$STAGE/" "$APPDIR/usr/share/enemy-tempest-reborn/"
cp "$ROOT/launcher/assets/images/alien.png" "$APPDIR/enemy-tempest-reborn.png"
cp "$ROOT/launcher/assets/images/alien.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/enemy-tempest-reborn.png"

cat >"$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$HERE/usr/share/enemy-tempest-reborn"
cd "$APP_ROOT"
exec "$APP_ROOT/run-linux.sh" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat >"$APPDIR/enemy-tempest-reborn.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Enemy: Tempest Reborn
Comment=Enemy Amiga launcher and FS-UAE package
Exec=AppRun
Icon=enemy-tempest-reborn
Categories=Game;
Terminal=false
EOF
cp "$APPDIR/enemy-tempest-reborn.desktop" "$APPDIR/usr/share/applications/enemy-tempest-reborn.desktop"

APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$APPIMAGE"
chmod +x "$APPIMAGE"
(
  cd "$OUT_DIR"
  sha256sum "$(basename "$APPIMAGE")" >"$(basename "$SUM")"
)

printf '%s\n' "$APPIMAGE"
printf '%s\n' "$SUM"
