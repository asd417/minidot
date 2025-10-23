#!/bin/bash

if ! command -v playerctl &> /dev/null; then
    echo "playerctl is not installed."
    exit 1
fi

get_spotify_artist_linux() {
  playerctl -p spotify metadata --format "{{ artist }}"
}

get_spotify_song_linux() {
  playerctl -p spotify metadata --format "{{ title }}"
}

if pgrep -x "spotify" > /dev/null; then
  artist=$(get_spotify_artist_linux)
  song=$(get_spotify_song_linux)

  if [[ -n "$song" ]]; then
    echo "${artist} - ${song}"
  else
    echo "Paused."
  fi
else
  echo "Not running."
fi
