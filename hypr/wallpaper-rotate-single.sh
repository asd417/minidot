#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
WALL_DIR="${WALL_DIR:-$HOME/Pictures/wallpapers}" # wallpaper directory
INTERVAL_SECONDS="${INTERVAL_SECONDS:-120}" # how long to wait between changes
TRANSITION="${TRANSITION:-grow}"
TRANSITION_DURATION="${TRANSITION_DURATION:-1}"
TRANSITION_FPS="${TRANSITION_FPS:-75}"
STATE_DIR="${STATE_DIR:-$HOME/.cache/wallcycle}"
RUN_MATUGEN="${RUN_MATUGEN:-1}"      # set to 0 to disable matugen
SWWW_NAMESPACE="${SWWW_NAMESPACE:-}" # optional: e.g. "main"

mkdir -p "$STATE_DIR"

# --- Helpers ---
die() {
  echo "Error: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

need swww
[ -d "$WALL_DIR" ] || die "Wallpaper dir not found: $WALL_DIR"

# Gather images
mapfile -t ALL_IMGS < <(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ "${#ALL_IMGS[@]}" -gt 0 ] || die "No images found in $WALL_DIR"

# Ensure swww daemon
if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  if [ -n "$SWWW_NAMESPACE" ]; then
    swww-daemon --namespace "$SWWW_NAMESPACE" &
  else
    swww-daemon &
  fi
  sleep 0.3
fi

# Pick an image not equal to the last one (global)
pick_image() {
  local last_file="$STATE_DIR/last_global.txt"
  local last=""
  [ -f "$last_file" ] && last="$(<"$last_file")"

  # Try a handful of random picks before allowing a repeat
  for _ in {1..50}; do
    local candidate="${ALL_IMGS[$RANDOM % ${#ALL_IMGS[@]}]}"
    if [[ "$candidate" != "$last" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  # Fallback: random
  echo "${ALL_IMGS[$RANDOM % ${#ALL_IMGS[@]}]}"
}

apply_wallpaper_all() {
  local img="$1"
  local ns_args=()
  [ -n "$SWWW_NAMESPACE" ] && ns_args=(--namespace "$SWWW_NAMESPACE")

  # NOTE: Without -o/--outputs, swww applies to all outputs.  # LOW CONFIDENCE: relies on manpage semantics
  swww img "$img" \
    -t "$TRANSITION" \
    --transition-duration "$TRANSITION_DURATION" \
    --transition-fps "$TRANSITION_FPS" \
    "${ns_args[@]}"
}

cycle_once() {
  local img
  img="$(pick_image)"

  # Optional: re-generate colorscheme once per cycle, and reload Hyprland if present
  if [[ "$RUN_MATUGEN" == "1" ]]; then
    if command -v matugen >/dev/null 2>&1; then
      matugen image "$img" || true
    fi
  fi
  hyprctl reload
  echo "$img" >"$STATE_DIR/last_global.txt"
  apply_wallpaper_all "$img"
}

main_loop() {
  while :; do
    cycle_once
    sleep "$INTERVAL_SECONDS"
  done
}

# --- Exec ---
if [ "${ONE_SHOT:-0}" = "1" ]; then
  cycle_once
else
  main_loop
fi
