#!/usr/bin/env bash
set -euo pipefail

# Config via env vars
STEP="${STEP:-0.5}"      # amount per tick
FPS="${FPS:-60}"         # frames per second
PAUSE="${PAUSE:-3}"      # seconds to wait at ends
MIN="${MIN:-0}"
MAX="${MAX:-100}"
PX_PER_CHAR="${PX_PER_CHAR:-8}"

sleep_dur="$(awk -v fps="$FPS" 'BEGIN{printf("%.6f", 1/fps)}')"

# Cheap float compare using bc -l
add() { echo "$1 + $2" | bc -l; }
sub() { echo "$1 - $2" | bc -l; }

while :; do
  song="$(~/.config/eww/scripts/spotify/spotify-song.sh)"
  len=${#song}
  px=$(( len * PX_PER_CHAR ))
  
  # forward
  v="$MIN"
  #while le "$v" "$MAX"; do
  while [ "$(echo "$v <= $MAX" | bc -l)" -eq 1 ]; do
    eww update scrollval="$v" || true
    v="$(add "$v" "$STEP")"
    sleep "$sleep_dur"
  done
  eww update songlength="$px" || true
  sleep "$PAUSE"
  eww update songlength="$px" || true

done