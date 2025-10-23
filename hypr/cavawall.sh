#!/usr/bin/env bash
pkill -f -- '--class=kitty-bg' || true

KITTY_DISABLE_WAYLAND=1 kitty -c ~/.config/hypr/kittycava.conf --class="kitty-bg" "$HOME/.config/hypr/cava.sh"