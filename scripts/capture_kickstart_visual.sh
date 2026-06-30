#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${1:-enemy1}"
PROFILE="${2:-a500}"
ROMSET="${3:-arosclosewbnop}"
DURATION="${4:-75}"
SHOT_AT="${5:-60}"
RUN_ID="${GAME}_${ROMSET}_${PROFILE}"
CONFIG="${ROOT}/configs/fs-uae/${RUN_ID}.fs-uae"
CAPTURE_ROOT="${ROOT}/work/kickstart-deps/visual"
CAPTURE_ID="${RUN_ID}_$(date +%Y%m%dT%H%M%S%z)"
CAPTURE_DIR="${CAPTURE_ROOT}/${CAPTURE_ID}"
LOG_DIR="${ROOT}/output/logs"
SCREENSHOT_DIR="${ROOT}/output/screenshots"
FSUAE_PROJECT_LOG="${LOG_DIR}/fs-uae.log.txt"
FS_UAE_BIN="${FS_UAE_BIN:-fs-uae}"

if [ ! -f "$CONFIG" ]; then
  echo "missing config: $CONFIG" >&2
  exit 2
fi
if ! command -v "$FS_UAE_BIN" >/dev/null 2>&1; then
  echo "missing fs-uae binary: $FS_UAE_BIN" >&2
  exit 127
fi
if ! command -v ydotool >/dev/null 2>&1; then
  echo "missing ydotool" >&2
  exit 127
fi

mkdir -p "$CAPTURE_DIR" "$LOG_DIR" "$SCREENSHOT_DIR"
cp "$CONFIG" "$CAPTURE_DIR/config.fs-uae"

cat >"$CAPTURE_DIR/manifest.txt" <<EOF
capture_id=${CAPTURE_ID}
run_id=${RUN_ID}
config=${CONFIG}
started_at=$(date -Is)
duration_seconds=${DURATION}
screenshot_at_seconds=${SHOT_AT}
fs_uae_bin=${FS_UAE_BIN}
EOF

"$FS_UAE_BIN" "$CONFIG" --stdout=1 >"$CAPTURE_DIR/fsuae.stdout.log" 2>&1 &
child_pid=$!

sleep "$SHOT_AT"
if command -v grim >/dev/null 2>&1; then
  grim "$CAPTURE_DIR/desktop_${SHOT_AT}s.png" || true
fi
{
  echo "screenshot_hotkey_at=$(date -Is)"
  echo "command=ydotool key 88:1 31:1 31:0 88:0; ydotool key 99:1 99:0"
} >"$CAPTURE_DIR/screenshot_hotkey.log"
ydotool key 88:1 31:1 31:0 88:0 >>"$CAPTURE_DIR/screenshot_hotkey.log" 2>&1 || true
ydotool key 99:1 99:0 >>"$CAPTURE_DIR/screenshot_hotkey.log" 2>&1 || true
sleep 2

remaining=$((DURATION - SHOT_AT))
if [ "$remaining" -gt 0 ]; then
  sleep "$remaining"
fi

if kill -0 "$child_pid" 2>/dev/null; then
  kill -TERM "$child_pid" 2>/dev/null || true
  wait "$child_pid" 2>/dev/null || true
fi

if [ -f "$FSUAE_PROJECT_LOG" ]; then
  cp "$FSUAE_PROJECT_LOG" "$CAPTURE_DIR/fs-uae.log.txt"
fi
find "$SCREENSHOT_DIR" -maxdepth 1 -type f -name "${RUN_ID}_*.png" -newer "$CAPTURE_DIR/manifest.txt" -exec cp {} "$CAPTURE_DIR/" \; || true

{
  echo "finished_at=$(date -Is)"
  echo "capture_dir=${CAPTURE_DIR}"
  shot="$(find "$CAPTURE_DIR" -maxdepth 1 -type f \( -name "${RUN_ID}_*.png" -o -name "desktop_${SHOT_AT}s.png" \) | sort | tail -n 1)"
  if [ -n "$shot" ]; then
    echo "screenshot=${shot}"
  else
    echo "screenshot=missing"
  fi
} >>"$CAPTURE_DIR/manifest.txt"

printf '%s\n' "$CAPTURE_DIR"
