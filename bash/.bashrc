#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
eval "$(starship init bash)"

# Alias útiles
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cat='bat'
alias grep='rg'
eval "$(zoxide init bash)"
fastfetch
. "$HOME/.cargo/env"

# Created by `pipx` on 2026-07-03 21:07:41
export PATH="$PATH:/home/skdrk/.local/bin"
[[ $- == *i* ]] && source /usr/share/blesh/ble.sh
bleopt complete_auto_history=1
_ble_complete_auto_source=(history)
ble-face auto_complete='fg=240'
