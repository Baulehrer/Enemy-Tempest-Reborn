#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_FS_UAE="${ROOT}/bin/fs-uae/fs-uae"
if [ ! -x "$DEFAULT_FS_UAE" ]; then
  DEFAULT_FS_UAE="fs-uae"
fi
FS_UAE_BIN="${FS_UAE_BIN:-$DEFAULT_FS_UAE}"
GAME="${1:-enemy1}"
LANGUAGE="${2:-de}"
PROFILE="${3:-a1200}"
MODE="${4:-game}"

case "${GAME}:${LANGUAGE}:${PROFILE}:${MODE}" in
  enemy1:de:a1200:game) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae" ;;
  enemy1:en:a1200:game) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_enemy1_en_a1200.fs-uae" ;;
  enemy2:de:a1200:game) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_enemy2_de_a1200.fs-uae" ;;
  enemy2:en:a1200:game) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_enemy2_en_a1200.fs-uae" ;;
  enemy1:de:a1200:intro) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae" ;;
  enemy1:en:a1200:intro) CONFIG="${ROOT}/configs/fs-uae/tempestreborn_intro_en_a1200.fs-uae" ;;
  *)
    echo "usage: $0 enemy1|enemy2 de|en [a1200] [game|intro]" >&2
    exit 2
    ;;
esac

if [[ "$FS_UAE_BIN" == */* ]]; then
  if [ ! -x "$FS_UAE_BIN" ]; then
    echo "missing fs-uae binary: ${FS_UAE_BIN}" >&2
    exit 127
  fi
elif ! command -v "$FS_UAE_BIN" >/dev/null 2>&1; then
  echo "missing fs-uae binary: ${FS_UAE_BIN}" >&2
  exit 127
fi

exec "$FS_UAE_BIN" "$CONFIG"
