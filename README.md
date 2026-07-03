# 🐧 Arch Linux Dotfiles

My personal Arch Linux configuration: **i3 + polybar + kitty + rofi**, themed with **Tokyo Night**.

![Arch](https://img.shields.io/badge/Arch_Linux-1793D1?logo=arch-linux&logoColor=white)
![i3](https://img.shields.io/badge/WM-i3-blue)
![X11](https://img.shields.io/badge/Display-X11-green)

## 📦 What's included

| Component | Tool |
|-----------|------|
| Window Manager | [i3](https://i3wm.org/) (X11) |
| Status Bar | [polybar](https://github.com/polybar/polybar) |
| Terminal | [kitty](https://sw.kovidgoyal.net/kitty/) (Tokyo Night theme, transparency) |
| Launcher | [rofi](https://github.com/davatorium/rofi) |
| Compositor | [picom](https://github.com/yshui/picom) (shadows, rounded corners) |
| Notifications | [dunst](https://dunst-project.org/) |
| Prompt | [starship](https://starship.rs/) |
| Shell | bash |
| Font | JetBrainsMono Nerd Font |
| GTK Theme | Tokyo Night / Arc-Dark + Papirus icons |

## 🚀 Installation

On a fresh Arch Linux install:

```bash
sudo pacman -S git
git clone https://github.com/skdrk/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script will:

1. Install all official repo packages (`pkglist.txt`)
2. Install [paru](https://github.com/Morganamilo/paru) (AUR helper) if missing
3. Install AUR packages (`aur-pkglist.txt`)
4. Deploy all configs using [GNU Stow](https://www.gnu.org/software/stow/) (existing files are backed up as `.bak`)

## ⌨️ Keybindings

| Shortcut | Action |
|----------|--------|
| `Super+Enter` | Terminal (kitty) |
| `Super+D` | App launcher (rofi) |
| `Super+Shift+F` | File manager (Thunar) |
| `Super+Shift+Q` | Close window |
| `Super+Shift+X` | Lock screen |
| `Super+Shift+P` | Power menu |
| `Super+Shift+V` | Clipboard history |
| `Print` | Screenshot (region select) |
| `Super+1..0` | Switch workspace |
| `Super+Shift+R` | Reload i3 |

## 📝 Notes

- Built and tested on Arch Linux inside **VMware** (X11 chosen over Wayland for proper host↔guest clipboard support via `autocutsel` + `open-vm-tools`).
- Wallpaper path: `~/Pictures/wallpapers/` (referenced by feh in i3 config).
- Display manager: LightDM with GTK greeter (optional, enable with `sudo systemctl enable lightdm`).

## 📂 Structure
dotfiles/
├── i3/          # i3 config
├── kitty/       # kitty terminal
├── polybar/     # status bar + power menu script
├── rofi/        # launcher theme
├── picom/       # compositor
├── dunst/       # notifications
├── starship/    # prompt
├── gtk/         # GTK theme settings
├── bash/        # .bashrc, .bash_profile, .xprofile
├── pkglist.txt      # official packages
├── aur-pkglist.txt  # AUR packages
└── install.sh       # installer script
