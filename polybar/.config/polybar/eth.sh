#!/usr/bin/env bash
ip=$(ip -4 addr show ens33 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$ip" ]; then
    echo "$ip"
fi
