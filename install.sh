#!/usr/bin/env bash
# Script para desplegar los dotfiles en un Arch nuevo
cd "$(dirname "$0")"

echo "==> Instalando paquetes de repos oficiales..."
sudo pacman -S --needed - < pkglist.txt

echo "==> Desplegando configs con stow..."
for dir in i3 kitty polybar rofi picom dunst starship gtk bash; do
    stow -v "$dir"
done

echo "==> Listo. Reinicia i3 con Super+Shift+R"
