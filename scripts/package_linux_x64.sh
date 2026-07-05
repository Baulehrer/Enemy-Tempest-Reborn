#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-v0.7}"
PKG="Enemy-Tempest-Reborn-${VERSION}-linux-x64"
OUT_DIR="${OUT_DIR:-${ROOT}/dist}"
STAGE="${OUT_DIR}/${PKG}"
ARCHIVE="${OUT_DIR}/${PKG}.tar.gz"
SUM="${ARCHIVE}.sha256"
FS_UAE_BUNDLE_BIN="${FS_UAE_BUNDLE_BIN:-}"

mkdir -p "$OUT_DIR"
rm -rf "$STAGE" "$ARCHIVE" "$SUM"
mkdir -p "$STAGE"

(
  cd "$ROOT/launcher"
  flutter build linux
)

rsync -a "$ROOT/launcher/build/linux/x64/release/bundle/" "$STAGE/launcher/"
rsync -a "$ROOT/configs" "$STAGE/"
rsync -a "$ROOT/assets" "$STAGE/"
rsync -a "$ROOT/roms" "$STAGE/"
mkdir -p "$STAGE/work/kickstart-deps"
rsync -a "$ROOT/work/kickstart-deps/patches" "$STAGE/work/kickstart-deps/"
rsync -a "$ROOT/docs" "$STAGE/"
cp "$ROOT/README.md" "$ROOT/README_DE.md" "$ROOT/LICENSES.md" "$STAGE/"

if [ -n "$FS_UAE_BUNDLE_BIN" ]; then
  if [ ! -x "$FS_UAE_BUNDLE_BIN" ]; then
    echo "FS_UAE_BUNDLE_BIN is not executable: $FS_UAE_BUNDLE_BIN" >&2
    exit 2
  fi
  mkdir -p "$STAGE/bin/fs-uae"
  cp "$FS_UAE_BUNDLE_BIN" "$STAGE/bin/fs-uae/fs-uae"
  chmod +x "$STAGE/bin/fs-uae/fs-uae"
  if [ -d /usr/share/fs-uae ]; then
    mkdir -p "$STAGE/bin/share"
    rsync -a /usr/share/fs-uae "$STAGE/bin/share/"
  fi
  if [ -f /usr/share/doc/fs-uae/COPYING ]; then
    cp /usr/share/doc/fs-uae/COPYING "$STAGE/bin/fs-uae/COPYING"
  fi
  if [ -f /usr/share/doc/fs-uae/README ]; then
    cp /usr/share/doc/fs-uae/README "$STAGE/bin/fs-uae/README"
  fi
  {
    echo "Bundled FS-UAE binary"
    echo "source_path=$FS_UAE_BUNDLE_BIN"
    "$FS_UAE_BUNDLE_BIN" --version 2>/dev/null | sed 's/^/version=/'
  } >"$STAGE/bin/fs-uae/BUNDLE_INFO.txt"
fi

cat >"$STAGE/run-linux.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
exec "$DIR/launcher/launcher"
EOF
chmod +x "$STAGE/run-linux.sh"

cat >"$STAGE/PACKAGE_README.txt" <<EOF
Enemy: Tempest Reborn ${VERSION} Linux x64

Start:
  ./run-linux.sh

If bin/fs-uae/fs-uae is present, the launcher uses that bundled emulator.
Runtime files are written to the user's application data directory.
EOF

tar -C "$OUT_DIR" -czf "$ARCHIVE" "$PKG"
(
  cd "$OUT_DIR"
  sha256sum "$(basename "$ARCHIVE")" >"$(basename "$SUM")"
)

printf '%s\n' "$ARCHIVE"
printf '%s\n' "$SUM"
