#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_FS_UAE="${ROOT}/bin/fs-uae/fs-uae"
if [ ! -x "$DEFAULT_FS_UAE" ]; then
  DEFAULT_FS_UAE="fs-uae"
fi

FS_UAE_BIN="${FS_UAE_BIN:-$DEFAULT_FS_UAE}"
BASE_CONFIG="${BASE_CONFIG:-${ROOT}/configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae}"
RUN_ID="$(date +%Y%m%dT%H%M%S%z)"
WORK_DIR="${ROOT}/work/graphics-filter-matrix/${RUN_ID}"
EVIDENCE_DIR="${ROOT}/evidence/screenshots/graphics-filter-matrix/${RUN_ID}"
LOG_DIR="${ROOT}/output/logs"
SCREENSHOT_DIR="${ROOT}/output/screenshots"
CAPTURE_AT="${CAPTURE_AT:-70}"
RUN_SECONDS="${RUN_SECONDS:-76}"
WINDOW_WIDTH="${WINDOW_WIDTH:-960}"
WINDOW_HEIGHT="${WINDOW_HEIGHT:-720}"

usage() {
  cat >&2 <<EOF
usage: $0 [variant ...]

Environment:
  FS_UAE_BIN     FS-UAE binary, default: bundled bin/fs-uae/fs-uae or fs-uae
  BASE_CONFIG    source config, default: German intro profile
  CAPTURE_AT     seconds before screenshots, default: 70
  RUN_SECONDS    hard stop in seconds, default: 76
  WINDOW_WIDTH   window width, default: 960
  WINDOW_HEIGHT  window height, default: 720

Variants:
  sharp smooth scanlines crt-effect crt-shader crt-hyllian crt-lottes
  hq2x scale2x scale4xhq xbrz4x xbrz6x super-xbr-3p scalefx
  scanline-3x sharp-bilinear
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [[ "$FS_UAE_BIN" == */* ]]; then
  if [ ! -x "$FS_UAE_BIN" ]; then
    echo "missing fs-uae binary: ${FS_UAE_BIN}" >&2
    exit 127
  fi
elif ! command -v "$FS_UAE_BIN" >/dev/null 2>&1; then
  echo "missing fs-uae binary: ${FS_UAE_BIN}" >&2
  exit 127
fi

if [ ! -f "$BASE_CONFIG" ]; then
  echo "missing base config: ${BASE_CONFIG}" >&2
  exit 2
fi

variants=("$@")
if [ "$#" -eq 0 ]; then
  variants=(
    sharp smooth scanlines
    crt-effect crt-shader crt-hyllian crt-lottes
    hq2x scale2x scale4xhq
    xbrz4x xbrz6x super-xbr-3p scalefx
    scanline-3x sharp-bilinear
  )
fi

take_desktop_shot() {
  local out="$1"
  local pid="${2:-}"
  local window_id=""

  if [ -n "$pid" ] && command -v xdotool >/dev/null 2>&1 && command -v magick >/dev/null 2>&1; then
    window_id="$(xdotool search --pid "$pid" 2>/dev/null | head -n 1 || true)"
    if [ -n "$window_id" ]; then
      magick import -window "$window_id" "$out" >/dev/null 2>&1 && return 0
    fi
  fi

  if command -v grim >/dev/null 2>&1; then
    grim "$out" >/dev/null 2>&1 && return 0
  fi
  if command -v gnome-screenshot >/dev/null 2>&1; then
    gnome-screenshot -f "$out" >/dev/null 2>&1 && return 0
  fi
  if command -v magick >/dev/null 2>&1; then
    magick import -window root "$out" >/dev/null 2>&1 && return 0
  fi
  if command -v import >/dev/null 2>&1; then
    import -window root "$out" >/dev/null 2>&1 && return 0
  fi
  return 1
}

send_fsuae_screenshot_hotkey() {
  local log_file="$1"
  if ! command -v ydotool >/dev/null 2>&1; then
    echo "fsuae_screenshot=skipped_ydotool_missing" >>"$log_file"
    return 0
  fi
  echo "fsuae_screenshot_hotkey_at=$(date -Is)" >>"$log_file"
  ydotool key 88:1 31:1 31:0 88:0 >>"$log_file" 2>&1 || true
}

variant_options() {
  case "$1" in
    sharp)
      cat <<EOF
texture_filter = nearest
smoothing = 0
scanlines = 0
EOF
      ;;
    smooth)
      cat <<EOF
texture_filter = linear
smoothing = 1
scanlines = 0
EOF
      ;;
    scanlines)
      cat <<EOF
texture_filter = nearest
smoothing = 0
scanlines = 1
EOF
      ;;
    crt-effect)
      cat <<EOF
texture_filter = nearest
smoothing = 0
effect = crt
EOF
      ;;
    crt-shader)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = crt
EOF
      ;;
    crt-hyllian)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = crt-hyllian
EOF
      ;;
    crt-lottes)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = crt-lottes
EOF
      ;;
    hq2x)
      cat <<EOF
texture_filter = nearest
smoothing = 0
effect = hq2x
EOF
      ;;
    scale2x)
      cat <<EOF
texture_filter = nearest
smoothing = 0
effect = scale2x
EOF
      ;;
    scale4xhq)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = scale4xhq
EOF
      ;;
    xbrz4x)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = xbrz4x
EOF
      ;;
    xbrz6x)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = xbrz6x
EOF
      ;;
    super-xbr-3p)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = super-xbr-3p
EOF
      ;;
    scalefx)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = scalefx
EOF
      ;;
    scanline-3x)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = scanline-3x
EOF
      ;;
    sharp-bilinear)
      cat <<EOF
texture_filter = nearest
smoothing = 0
shader = sharp-bilinear
EOF
      ;;
    *)
      echo "unknown variant: $1" >&2
      return 2
      ;;
  esac
}

write_variant_config() {
  local variant="$1"
  local out="$2"

  sed \
    -e '/^fullscreen = /d' \
    -e '/^window_width = /d' \
    -e '/^window_height = /d' \
    -e '/^texture_filter = /d' \
    -e '/^smoothing = /d' \
    -e '/^scanlines = /d' \
    -e '/^effect = /d' \
    -e '/^shader = /d' \
    -e '/^uaelogfile = /d' \
    "$BASE_CONFIG" >"$out"

  {
    echo "fullscreen = 0"
    echo "window_width = ${WINDOW_WIDTH}"
    echo "window_height = ${WINDOW_HEIGHT}"
    echo "uaelogfile = output/logs/graphics_filter_${variant}.log"
    variant_options "$variant"
  } >>"$out"
}

run_variant() {
  local variant="$1"
  local variant_dir="${WORK_DIR}/${variant}"
  local config="${variant_dir}/${variant}.fs-uae"
  local event_log="${variant_dir}/events.log"
  local stdout_log="${variant_dir}/fsuae.stdout.log"
  local child_pid
  local elapsed=0
  local status="unknown"

  mkdir -p "$variant_dir" "$LOG_DIR" "$SCREENSHOT_DIR"
  write_variant_config "$variant" "$config"

  {
    echo "variant=${variant}"
    echo "base_config=${BASE_CONFIG}"
    echo "config=${config}"
    echo "started_at=$(date -Is)"
    echo "capture_at=${CAPTURE_AT}"
    echo "run_seconds=${RUN_SECONDS}"
    echo "window=${WINDOW_WIDTH}x${WINDOW_HEIGHT}"
    echo "fs_uae_bin=${FS_UAE_BIN}"
    echo "options:"
    variant_options "$variant" | sed 's/^/  /'
  } >"${variant_dir}/manifest.txt"

  "$FS_UAE_BIN" "$config" --stdout=1 >"$stdout_log" 2>&1 &
  child_pid=$!
  echo "pid=${child_pid}" >>"${variant_dir}/manifest.txt"

  while [ "$elapsed" -lt "$CAPTURE_AT" ] && kill -0 "$child_pid" 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if kill -0 "$child_pid" 2>/dev/null; then
    if take_desktop_shot "${variant_dir}/desktop_${CAPTURE_AT}s.png" "$child_pid"; then
      echo "desktop_screenshot=${variant_dir}/desktop_${CAPTURE_AT}s.png" >>"$event_log"
    else
      echo "desktop_screenshot=missing" >>"$event_log"
    fi
    send_fsuae_screenshot_hotkey "$event_log"
  fi

  while [ "$elapsed" -lt "$RUN_SECONDS" ] && kill -0 "$child_pid" 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if kill -0 "$child_pid" 2>/dev/null; then
    status="timeout_terminated"
    kill -TERM "$child_pid" 2>/dev/null || true
    sleep 2
    if kill -0 "$child_pid" 2>/dev/null; then
      status="timeout_killed"
      kill -KILL "$child_pid" 2>/dev/null || true
    fi
    wait "$child_pid" 2>/dev/null || true
  else
    wait "$child_pid" 2>/dev/null || true
    status="exited"
  fi

  find "$SCREENSHOT_DIR" -maxdepth 1 -type f -name "tempestreborn_intro_de_a1200_*.png" -newer "${variant_dir}/manifest.txt" -exec cp {} "$variant_dir/" \; 2>/dev/null || true
  cp "$config" "$variant_dir/config.fs-uae"

  {
    echo "finished_at=$(date -Is)"
    echo "status=${status}"
    find "$variant_dir" -maxdepth 1 -type f -name "*.png" | sort | sed 's/^/screenshot=/'
  } >>"${variant_dir}/manifest.txt"

  mkdir -p "${EVIDENCE_DIR}/${variant}"
  cp "${variant_dir}/manifest.txt" "${EVIDENCE_DIR}/${variant}/"
  cp "${variant_dir}/config.fs-uae" "${EVIDENCE_DIR}/${variant}/"
  cp "$event_log" "${EVIDENCE_DIR}/${variant}/events.log" 2>/dev/null || true
  cp "$stdout_log" "${EVIDENCE_DIR}/${variant}/fsuae.stdout.log" 2>/dev/null || true
  find "$variant_dir" -maxdepth 1 -type f -name "*.png" -exec cp {} "${EVIDENCE_DIR}/${variant}/" \; 2>/dev/null || true

  printf '%-12s %s\n' "$variant" "$status" | tee -a "${WORK_DIR}/summary.txt"
}

mkdir -p "$WORK_DIR" "$EVIDENCE_DIR"
{
  echo "run_id=${RUN_ID}"
  echo "started_at=$(date -Is)"
  echo "base_config=${BASE_CONFIG}"
  echo "capture_at=${CAPTURE_AT}"
  echo "run_seconds=${RUN_SECONDS}"
  echo "window=${WINDOW_WIDTH}x${WINDOW_HEIGHT}"
  echo "variants=${variants[*]}"
} >"${WORK_DIR}/run_manifest.txt"

for variant in "${variants[@]}"; do
  run_variant "$variant"
done

cp "${WORK_DIR}/run_manifest.txt" "${EVIDENCE_DIR}/"
cp "${WORK_DIR}/summary.txt" "${EVIDENCE_DIR}/"
echo "finished_at=$(date -Is)" >>"${WORK_DIR}/run_manifest.txt"
printf '%s\n' "$EVIDENCE_DIR"
