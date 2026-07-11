#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-v0.8}"
PKG="Enemy-Tempest-Reborn-${VERSION}-macos-universal"
OUT_DIR="${OUT_DIR:-${ROOT}/dist}"
STAGE="${OUT_DIR}/${PKG}"
ARCHIVE="${OUT_DIR}/${PKG}.zip"
SUM="${ARCHIVE}.sha256"
FS_UAE_BUNDLE_BIN="${FS_UAE_BUNDLE_BIN:-}"

mkdir -p "$OUT_DIR"
rm -rf "$STAGE" "$ARCHIVE" "$SUM"
mkdir -p "$STAGE"

(
  cd "$ROOT/launcher"
  flutter build macos --release
)

mkdir -p "$STAGE/launcher"
cp -R "$ROOT/launcher/build/macos/Build/Products/Release/launcher.app" "$STAGE/launcher/"

for name in configs assets roms docs; do
  if [ -e "$ROOT/$name" ]; then
    cp -R "$ROOT/$name" "$STAGE/"
  fi
done

if [ -d "$ROOT/work/kickstart-deps/patches" ]; then
  mkdir -p "$STAGE/work/kickstart-deps"
  cp -R "$ROOT/work/kickstart-deps/patches" "$STAGE/work/kickstart-deps/"
fi

cp "$ROOT/README.md" "$ROOT/README_DE.md" "$ROOT/LICENSES.md" "$STAGE/"

if [ -n "$FS_UAE_BUNDLE_BIN" ]; then
  if [ ! -x "$FS_UAE_BUNDLE_BIN" ]; then
    echo "FS_UAE_BUNDLE_BIN is not executable: $FS_UAE_BUNDLE_BIN" >&2
    exit 2
  fi
  mkdir -p "$STAGE/bin/fs-uae"
  if [[ "$FS_UAE_BUNDLE_BIN" == *.app/Contents/MacOS/* ]]; then
    APP_ROOT="${FS_UAE_BUNDLE_BIN%%.app/Contents/MacOS/*}.app"
    cp -R "$APP_ROOT" "$STAGE/bin/fs-uae/"
    APP_NAME="$(basename "$APP_ROOT")"
    cat >"$STAGE/bin/fs-uae/fs-uae" <<EOF
#!/usr/bin/env bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$DIR/${APP_NAME}/Contents/MacOS/$(basename "$FS_UAE_BUNDLE_BIN")" "\$@"
EOF
  else
    cp "$FS_UAE_BUNDLE_BIN" "$STAGE/bin/fs-uae/fs-uae"
  fi
  chmod +x "$STAGE/bin/fs-uae/fs-uae"
  {
    echo "Bundled FS-UAE binary"
    echo "source_path=$FS_UAE_BUNDLE_BIN"
    "$FS_UAE_BUNDLE_BIN" --version 2>/dev/null | sed 's/^/version=/'
  } >"$STAGE/bin/fs-uae/BUNDLE_INFO.txt"
fi

cat >"$STAGE/run-macos.command" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
open "$DIR/launcher/launcher.app"
EOF
chmod +x "$STAGE/run-macos.command"

cat >"$STAGE/PACKAGE_README.txt" <<EOF
Enemy: Tempest Reborn ${VERSION} macOS

Start:
  run-macos.command

If bin/fs-uae/fs-uae is present, the launcher uses that bundled emulator.
Runtime files are written to the user's application data directory.
EOF

(
  cd "$OUT_DIR"
  zip -qry "$(basename "$ARCHIVE")" "$PKG"
  shasum -a 256 "$(basename "$ARCHIVE")" >"$(basename "$SUM")"
)

printf '%s\n' "$ARCHIVE"
printf '%s\n' "$SUM"
