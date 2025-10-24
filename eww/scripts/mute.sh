#!/usr/bin/env bash
# toggle-mute.sh — Toggle/Query mute via wpctl (PipeWire)
# Usage:
#   ./toggle-mute.sh                 # toggle mute on default *sink*
#   ./toggle-mute.sh --icon          # print 🔇/🔊 monochrome icon (for bars)
#   ./toggle-mute.sh --status        # print "muted" or "unmuted"
#   ./toggle-mute.sh --mute          # force mute
#   ./toggle-mute.sh --unmute        # force unmute
#   ./toggle-mute.sh --source        # operate on default *source* (mic)
#   ./toggle-mute.sh --id 55         # operate on a specific node id (sink/source)
#
# Notes:
# - Defaults to @DEFAULT_AUDIO_SINK@ unless --source or --id is given.

set -euo pipefail

# --- deps ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 127; }; }
need wpctl
need awk
need grep

# --- config/icons (monochrome/text presentation) ---
ICON_MUTED=$'\U0001F507\uFE0E'   # 🔇︎
ICON_LOUD=$'\U0001F50A\uFE0E'    # 🔊︎

# --- args ---
ACT="toggle"     # toggle | mute | unmute | status | icon
KIND="sink"      # sink | source
TARGET=""        # explicit numeric id
while (( $# )); do
  case "$1" in
    --mute)    ACT="mute" ;;
    --unmute)  ACT="unmute" ;;
    --toggle)  ACT="toggle" ;;
    --status)  ACT="status" ;;
    --icon)    ACT="icon" ;;
    --sink)    KIND="sink" ;;
    --source)  KIND="source" ;;
    --id)      shift; TARGET="${1:-}";;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# --- target resolver ---
resolve_target() {
  if [[ -n "$TARGET" ]]; then
    echo "$TARGET"
  else
    if [[ "$KIND" == "source" ]]; then
      echo "@DEFAULT_AUDIO_SOURCE@"
    else
      echo "@DEFAULT_AUDIO_SINK@"
    fi
  fi
}

TGT="$(resolve_target)"

# --- helpers ---
is_muted() {
  # wpctl get-volume prints e.g.: "Volume: 0.80 [MUTED]" when muted
  # shellcheck disable=SC2312
  if wpctl get-volume "$TGT" | grep -q '\[MUTED\]'; then
    return 0
  else
    return 1
  fi
}

print_status() {
  if is_muted; then
    echo true
  else
    echo false
  fi
}

print_icon() {
  if is_muted; then
    echo "$ICON_MUTED"
  else
    echo "$ICON_LOUD"
  fi
}

# --- actions ---
case "$ACT" in
  toggle)
    wpctl set-mute "$TGT" toggle >/dev/null
    ;;
  mute)
    wpctl set-mute "$TGT" 1 >/dev/null
    ;;
  unmute)
    wpctl set-mute "$TGT" 0 >/dev/null
    ;;
  status)
    print_status
    exit 0
    ;;
  icon)
    print_icon
    exit 0
    ;;
  *)
    echo "Internal error: unknown action '$ACT'" >&2
    exit 3
    ;;
esac

# After changing state, print the new status for convenience (script output is useful in bars)
print_status
