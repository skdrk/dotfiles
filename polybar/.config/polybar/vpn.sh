#!/usr/bin/env bash
while true; do
    ip=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$ip" ]; then
        printf '󰖂 %s\n' "$ip"
    else
        printf '\n'
    fi
    sleep 2
done
