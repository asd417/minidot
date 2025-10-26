#!/usr/bin/env bash
set -euo pipefail

# Path to Matugen-generated Hyprland color config
MATUGEN_COLORS="${XDG_CACHE_HOME:-$HOME/.config}/hypr/conf/colors.conf"

if [[ ! -f "$MATUGEN_COLORS" ]]; then
    echo "Matugen colors file not found: $MATUGEN_COLORS"
    exit 1
fi

# Apply each line dynamically
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    hyprctl keyword "$key" "$value" >/dev/null 2>&1
done < "$MATUGEN_COLORS"

# notify-send "Matugen → Hyprland" "Theme colors applied successfully 🌈"