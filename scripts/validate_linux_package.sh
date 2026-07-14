#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <staged-package-directory>" >&2
  exit 2
fi

STAGE="$(cd "$1" && pwd)"
for path in \
  launcher/launcher \
  run-linux.sh \
  bin/fs-uae/fs-uae \
  bin/fs-uae/BUNDLE_INFO.txt \
  PACKAGE_CONTENTS.sha256 \
  docs/ROADMAP_TO_V1.0.md \
  docs/INTRO_1.0_ACCEPTANCE.md \
  docs/THIRD_PARTY_SOURCE.md; do
  if [ ! -e "$STAGE/$path" ]; then
    echo "Missing package entry: $path" >&2
    exit 1
  fi
done

if [ ! -x "$STAGE/launcher/launcher" ] || \
   [ ! -x "$STAGE/run-linux.sh" ] || \
   [ ! -x "$STAGE/bin/fs-uae/fs-uae" ]; then
  echo "A package entry that must be executable is not executable" >&2
  exit 1
fi

(
  cd "$STAGE"
  sha256sum -c PACKAGE_CONTENTS.sha256 >/dev/null
)

"$STAGE/bin/fs-uae/fs-uae" --version >/dev/null
echo "Linux package validation passed: $STAGE"
