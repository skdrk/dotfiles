#!/usr/bin/env bash
chosen=$(printf " Apagar\n Reiniciar\n Cerrar sesión\n Bloquear" | rofi -dmenu -i -p "Power")
case "$chosen" in
    *Apagar) systemctl poweroff ;;
    *Reiniciar) systemctl reboot ;;
    *"Cerrar sesión") i3-msg exit ;;
    *Bloquear) i3lock -c 1a1b26 ;;
esac
