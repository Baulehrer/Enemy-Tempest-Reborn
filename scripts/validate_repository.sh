#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/version.sh"

PUBSPEC_VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' "$ROOT/launcher/pubspec.yaml")"
if [ "$PUBSPEC_VERSION" != "$APP_VERSION" ]; then
  echo "Version mismatch: app=$APP_VERSION pubspec=$PUBSPEC_VERSION" >&2
  exit 1
fi

for file in README.md README_DE.md CHANGELOG.md docs/ROADMAP_TO_V1.0.md docs/RELEASE_CHECKLIST.md docs/INTRO_1.0_ACCEPTANCE.md docs/THIRD_PARTY_SOURCE.md; do
  if [ ! -s "$ROOT/$file" ]; then
    echo "Missing required release document: $file" >&2
    exit 1
  fi
done

for config in "$ROOT"/configs/fs-uae/tempestreborn_*.fs-uae; do
  while IFS= read -r value; do
    case "$value" in
      /*) candidate="$value" ;;
      *) candidate="$ROOT/$value" ;;
    esac
    if [ ! -e "$candidate" ]; then
      echo "Missing profile dependency in $(basename "$config"): $value" >&2
      exit 1
    fi
  done < <(sed -n 's/^[[:space:]]*\(data_dir\|kickstart_file\|kickstart_ext_file\|floppy_drive_[0-3]\)[[:space:]]*=[[:space:]]*//p' "$config")
done

for manifest in "$ROOT"/work/kickstart-deps/patches/*/manifest.txt; do
  if [ ! -s "$manifest" ]; then
    echo "Missing patch manifest: $manifest" >&2
    exit 1
  fi
done

if rg -n 'v0\.7\.1|Version 0\.8|Version 0.8' \
  "$ROOT/.github" "$ROOT/README.md" "$ROOT/README_DE.md" \
  "$ROOT/docs/RELEASE_PACKAGING.md"; then
  echo "Stale release version found" >&2
  exit 1
fi

echo "Repository validation passed for $APP_VERSION"
