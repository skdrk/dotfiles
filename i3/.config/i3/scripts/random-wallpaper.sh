#!/usr/bin/env bash
# Cambia el fondo de pantalla al siguiente de ~/.config/wallpapers (en orden,
# cíclico) y guarda cuál es para que el lockscreen (lock.sh) use la misma.
set -euo pipefail

WALL_DIR="$HOME/.config/wallpapers"
CACHE_FILE="$HOME/.cache/current_wallpaper"

mapfile -t images < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

if [ ${#images[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No hay imágenes en $WALL_DIR"
    exit 1
fi

current="$(cat "$CACHE_FILE" 2>/dev/null || true)"
next_index=0

for i in "${!images[@]}"; do
    if [ "${images[$i]}" = "$current" ]; then
        next_index=$(( (i + 1) % ${#images[@]} ))
        break
    fi
done

pick="${images[$next_index]}"

feh --bg-scale "$pick"
echo "$pick" > "$CACHE_FILE"
notify-send "Wallpaper" "Fondo cambiado a $(basename "$pick")"
