#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${1:-enemy1}"
PROFILE="${2:-a1200}"
ROMSET="${3:-arosclosewbnopdiag}"
DURATION="${4:-310}"
INPUT_AT="${5:-235}"
RUN_ID="${GAME}_${ROMSET}_${PROFILE}"
CONFIG="${ROOT}/configs/fs-uae/${RUN_ID}.fs-uae"
CAPTURE_ROOT="${ROOT}/work/kickstart-deps/visual"
CAPTURE_ID="${RUN_ID}_input_$(date +%Y%m%dT%H%M%S%z)"
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
input_at_seconds=${INPUT_AT}
fs_uae_bin=${FS_UAE_BIN}
EOF

"$FS_UAE_BIN" "$CONFIG" --stdout=1 >"$CAPTURE_DIR/fsuae.stdout.log" 2>&1 &
child_pid=$!

shot() {
  local label="$1"
  {
    echo "screenshot_${label}_at=$(date -Is)"
    echo "command=ydotool key 88:1 31:1 31:0 88:0"
  } >>"$CAPTURE_DIR/input_probe.log"
  ydotool key 88:1 31:1 31:0 88:0 >>"$CAPTURE_DIR/input_probe.log" 2>&1 || true
  sleep 2
}

send_key() {
  local label="$1"
  local key="$2"
  {
    echo "input_${label}_at=$(date -Is)"
    echo "command=ydotool key ${key}:1 ${key}:0"
  } >>"$CAPTURE_DIR/input_probe.log"
  ydotool key "${key}:1" "${key}:0" >>"$CAPTURE_DIR/input_probe.log" 2>&1 || true
  sleep 2
}

sleep "$INPUT_AT"
shot "before"

# Common FS-UAE/Amiga game activation keys: Space, Return, left Ctrl, left Alt,
# cursor directions, and F1. This deliberately avoids destructive emulator keys.
send_key "space" 57
send_key "return" 28
send_key "left_ctrl_fire" 29
send_key "left_alt_fire" 56
send_key "cursor_up" 103
send_key "cursor_down" 108
send_key "cursor_left" 105
send_key "cursor_right" 106
send_key "f1" 59

shot "after"

remaining=$((DURATION - INPUT_AT - 25))
if [ "$remaining" -gt 0 ]; then
  sleep "$remaining"
fi

shot "late"

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
  find "$CAPTURE_DIR" -maxdepth 1 -type f -name "${RUN_ID}_*.png" | sort | sed 's/^/screenshot=/'
} >>"$CAPTURE_DIR/manifest.txt"

printf '%s\n' "$CAPTURE_DIR"
