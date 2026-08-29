#!/usr/bin/env bash
# Bloquea la pantalla usando el mismo fondo de pantalla actual.
CACHE_FILE="$HOME/.cache/current_wallpaper"
wall="$(cat "$CACHE_FILE" 2>/dev/null || true)"

if [ -n "$wall" ] && [ -f "$wall" ]; then
    i3lock -i "$wall"
else
    i3lock -c 1a1b26
fi
