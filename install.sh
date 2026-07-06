#!/usr/bin/env bash
# ==============================================
#  Dotfiles installer - Arch Linux + i3 setup
# ==============================================
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

STOW_PACKAGES=(i3 kitty polybar rofi picom dunst starship gtk bash wallpapers)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$1"; }

# --- 1. Official repo packages ---
if [[ -f pkglist.txt ]]; then
    info "Installing official repo packages..."
    sudo pacman -Syu --needed --noconfirm - < pkglist.txt || warn "Some packages failed, continuing..."
else
    warn "pkglist.txt not found, skipping official packages."
fi

# --- 2. Install paru (AUR helper) if missing ---
if ! command -v paru &>/dev/null; then
    info "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# --- 3. AUR packages ---
if [[ -f aur-pkglist.txt ]]; then
    info "Installing AUR packages..."
    paru -S --needed --noconfirm - < aur-pkglist.txt || warn "Some AUR packages failed, review manually."
else
    warn "aur-pkglist.txt not found, skipping AUR packages."
fi

# --- 4. Python tools via pipx ---
if [[ -f pipx-pkglist.txt ]]; then
    info "Installing Python tools via pipx..."
    sudo pacman -S --needed --noconfirm python-pipx rust
    while IFS= read -r tool; do
        [[ -n "$tool" ]] && pipx install "$tool" || warn "pipx failed for $tool"
    done < pipx-pkglist.txt
    pipx ensurepath
fi

# --- 5. Deploy dotfiles with stow ---
info "Deploying dotfiles with stow..."
sudo pacman -S --needed --noconfirm stow

for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        while IFS= read -r -d '' file; do
            rel="${file#"$pkg"/}"
            target="$HOME/$rel"
            if [[ -e "$target" && ! -L "$target" ]]; then
                warn "Backing up existing $target -> $target.bak"
                mv "$target" "$target.bak"
            fi
        done < <(find "$pkg" -type f -print0)
        stow -v "$pkg"
        info "Stowed: $pkg"
    else
        warn "Package dir '$pkg' not found, skipping."
    fi
done

# --- 6. Post-install notes ---
info "Done!"
echo ""
echo "  Next steps:"
echo "  - Reboot or reload i3 (Super+Shift+R)"
echo "  - Enable login manager: sudo systemctl enable lightdm"
echo "  - Wallpaper is at ~/.config/wallpapers/ (referenced by i3 config)"
echo "  - Open a new terminal so pipx PATH takes effect"
echo ""