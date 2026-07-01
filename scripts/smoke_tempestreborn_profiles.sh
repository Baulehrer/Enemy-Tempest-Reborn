#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_FS_UAE="${ROOT}/bin/fs-uae/fs-uae"
if [ ! -x "$DEFAULT_FS_UAE" ]; then
  DEFAULT_FS_UAE="fs-uae"
fi
FS_UAE_BIN="${FS_UAE_BIN:-$DEFAULT_FS_UAE}"
CAPTURE_ROOT="${ROOT}/work/launcher-smoke"
RUN_ID="$(date +%Y%m%dT%H%M%S%z)"
RUN_DIR="${CAPTURE_ROOT}/${RUN_ID}"
LOG_DIR="${ROOT}/output/logs"
SCREENSHOT_DIR="${ROOT}/output/screenshots"
GAME_DURATION="${GAME_DURATION:-45}"
INTRO_DURATION="${INTRO_DURATION:-30}"
GAME_SHOTS="${GAME_SHOTS:-20 40}"
INTRO_SHOTS="${INTRO_SHOTS:-20}"
INTRO_INPUT_AT="${INTRO_INPUT_AT:-18}"

usage() {
  cat >&2 <<EOF
usage: $0 [all|enemy1-de|enemy1-en|enemy2-de|enemy2-en|intro-de|intro-en ...]

Environment:
  FS_UAE_BIN       FS-UAE binary, default: fs-uae
  GAME_DURATION   seconds per game profile, default: 45
  INTRO_DURATION  seconds per intro profile, default: 30
  GAME_SHOTS      game screenshot seconds, default: "20 40"
  INTRO_SHOTS     intro screenshot seconds, default: "20"
  INTRO_INPUT_AT  intro quit-input time, default: 18
EOF
}

config_for_profile() {
  case "$1" in
    enemy1-de) echo "${ROOT}/configs/fs-uae/tempestreborn_enemy1_de_a1200.fs-uae" ;;
    enemy1-en) echo "${ROOT}/configs/fs-uae/tempestreborn_enemy1_en_a1200.fs-uae" ;;
    enemy2-de) echo "${ROOT}/configs/fs-uae/tempestreborn_enemy2_de_a1200.fs-uae" ;;
    enemy2-en) echo "${ROOT}/configs/fs-uae/tempestreborn_enemy2_en_a1200.fs-uae" ;;
    intro-de) echo "${ROOT}/configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae" ;;
    intro-en) echo "${ROOT}/configs/fs-uae/tempestreborn_intro_en_a1200.fs-uae" ;;
    *) return 1 ;;
  esac
}

duration_for_profile() {
  case "$1" in
    intro-*) echo "$INTRO_DURATION" ;;
    *) echo "$GAME_DURATION" ;;
  esac
}

shots_for_profile() {
  case "$1" in
    intro-*) echo "$INTRO_SHOTS" ;;
    *) echo "$GAME_SHOTS" ;;
  esac
}

take_desktop_shot() {
  local out="$1"
  if command -v grim >/dev/null 2>&1; then
    grim "$out" >/dev/null 2>&1 && return 0
  fi
  if command -v gnome-screenshot >/dev/null 2>&1; then
    gnome-screenshot -f "$out" >/dev/null 2>&1 && return 0
  fi
  if command -v import >/dev/null 2>&1; then
    import -window root "$out" >/dev/null 2>&1 && return 0
  fi
  return 1
}

send_fsuae_screenshot_hotkey() {
  local log_file="$1"
  if ! command -v ydotool >/dev/null 2>&1; then
    echo "ydotool=missing" >>"$log_file"
    return 0
  fi
  {
    echo "fsuae_screenshot_hotkey_at=$(date -Is)"
    echo "command=ydotool key 88:1 31:1 31:0 88:0"
  } >>"$log_file"
  ydotool key 88:1 31:1 31:0 88:0 >>"$log_file" 2>&1 || true
}

send_intro_quit_input() {
  local log_file="$1"
  if ! command -v ydotool >/dev/null 2>&1; then
    echo "intro_quit_input=skipped_ydotool_missing" >>"$log_file"
    return 0
  fi
  {
    echo "intro_quit_input_at=$(date -Is)"
    echo "command=ydotool key 57:1 57:0"
  } >>"$log_file"
  ydotool key 57:1 57:0 >>"$log_file" 2>&1 || true
}

run_profile() {
  local profile="$1"
  local config
  local duration
  local shots
  local profile_dir
  local event_log
  local stdout_log
  local child_pid
  local status="unknown"

  config="$(config_for_profile "$profile")"
  duration="$(duration_for_profile "$profile")"
  shots="$(shots_for_profile "$profile")"
  profile_dir="${RUN_DIR}/${profile}"
  event_log="${profile_dir}/events.log"
  stdout_log="${profile_dir}/fsuae.stdout.log"

  if [ ! -f "$config" ]; then
    echo "missing config for ${profile}: ${config}" >&2
    return 2
  fi

  mkdir -p "$profile_dir" "$LOG_DIR" "$SCREENSHOT_DIR"
  cp "$config" "${profile_dir}/config.fs-uae"

  {
    echo "profile=${profile}"
    echo "config=${config}"
    echo "started_at=$(date -Is)"
    echo "duration_seconds=${duration}"
    echo "screenshot_seconds=${shots}"
    echo "fs_uae_bin=${FS_UAE_BIN}"
  } >"${profile_dir}/manifest.txt"

  "$FS_UAE_BIN" "$config" --stdout=1 >"$stdout_log" 2>&1 &
  child_pid=$!
  echo "pid=${child_pid}" >>"${profile_dir}/manifest.txt"

  local elapsed=0
  local intro_input_sent=0
  for shot_at in $shots; do
    while [ "$elapsed" -lt "$shot_at" ] && kill -0 "$child_pid" 2>/dev/null; do
      if [[ "$profile" == intro-* ]] && [ "$intro_input_sent" -eq 0 ] && [ "$elapsed" -ge "$INTRO_INPUT_AT" ]; then
        send_intro_quit_input "$event_log"
        intro_input_sent=1
      fi
      sleep 1
      elapsed=$((elapsed + 1))
    done
    if ! kill -0 "$child_pid" 2>/dev/null; then
      break
    fi
    if take_desktop_shot "${profile_dir}/desktop_${shot_at}s.png"; then
      echo "desktop_screenshot_${shot_at}s=${profile_dir}/desktop_${shot_at}s.png" >>"$event_log"
    else
      echo "desktop_screenshot_${shot_at}s=missing" >>"$event_log"
    fi
    send_fsuae_screenshot_hotkey "$event_log"
    sleep 2
    elapsed=$((elapsed + 2))
  done

  if [[ "$profile" == intro-* ]] && [ "$intro_input_sent" -eq 0 ] && kill -0 "$child_pid" 2>/dev/null; then
    while [ "$elapsed" -lt "$INTRO_INPUT_AT" ] && kill -0 "$child_pid" 2>/dev/null; do
      sleep 1
      elapsed=$((elapsed + 1))
    done
    if kill -0 "$child_pid" 2>/dev/null; then
      send_intro_quit_input "$event_log"
      intro_input_sent=1
    fi
  fi

  while kill -0 "$child_pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$duration" ]; then
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if kill -0 "$child_pid" 2>/dev/null; then
    status="timeout_terminated"
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  else
    wait "$child_pid" 2>/dev/null || true
    status="exited"
  fi

  if take_desktop_shot "${profile_dir}/desktop_final.png"; then
    echo "desktop_final=${profile_dir}/desktop_final.png" >>"$event_log"
  else
    echo "desktop_final=missing" >>"$event_log"
  fi

  find "$SCREENSHOT_DIR" -maxdepth 1 -type f -name "tempestreborn_${profile//-/_}_a1200_*.png" -newer "${profile_dir}/manifest.txt" -exec cp {} "$profile_dir/" \; 2>/dev/null || true

  {
    echo "finished_at=$(date -Is)"
    echo "status=${status}"
    echo "capture_dir=${profile_dir}"
    find "$profile_dir" -maxdepth 1 -type f -name "*.png" | sort | sed 's/^/screenshot=/'
  } >>"${profile_dir}/manifest.txt"

  printf '%-10s %s\n' "$profile" "$status" | tee -a "${RUN_DIR}/summary.txt"
}

if [ "${1:-all}" = "-h" ] || [ "${1:-all}" = "--help" ]; then
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

profiles=("$@")
if [ "$#" -eq 0 ] || [ "${1:-all}" = "all" ]; then
  profiles=(enemy1-de enemy1-en enemy2-de enemy2-en intro-de intro-en)
fi

mkdir -p "$RUN_DIR"
{
  echo "run_id=${RUN_ID}"
  echo "started_at=$(date -Is)"
  echo "root=${ROOT}"
  echo "profiles=${profiles[*]}"
} >"${RUN_DIR}/run_manifest.txt"

for profile in "${profiles[@]}"; do
  if ! config_for_profile "$profile" >/dev/null; then
    echo "unknown profile: ${profile}" >&2
    usage
    exit 2
  fi
  run_profile "$profile"
done

echo "finished_at=$(date -Is)" >>"${RUN_DIR}/run_manifest.txt"
printf '%s\n' "$RUN_DIR"
